#!/usr/bin/env ruby

require "yaml"
require "octokit"

class Work
  attr_reader \
    :date_range,
    :repo,
    :token

  MERGE_COMMIT = ["Merge", "branch", "into"]

  def initialize(date_range:, repo:, token:)
    @date_range  = parse_date_range(date_range)
    @repo        = repo
    @token       = token
  end

  def reviewed
    pulls = client.search_issues("-author:#{username} repo:#{repo} reviewed-by:#{username} type:pr updated:>=#{date_range.begin}", { per_page: 100 }).items

    pulls.select { |p| filter_reviews(p).any? }
  end

  def worked_on
    pulls = client.search_issues("repo:#{repo} type:pr updated:>=#{date_range.begin}", { per_page: 100 }).items

    pulls.each_with_object({}) do |pull, hash|
      commits = filter_commits(pull)
      hash[pull] = commits if commits.any?
    end
  end

  private

  def client
    @client ||= Octokit::Client.new(access_token: token)
  end

  def user
    @user ||= client.user
  end

  def username
    user.login
  end

  def parse_date_range(date_range)
    zone       = DateTime.now.zone
    date_range = date_range.split("..")

    from = "#{date_range.first}T00:00:00#{zone}"
    to   = "#{date_range.last}T23:59:59#{zone}"

    DateTime.parse(from)..DateTime.parse(to)
  end

  def filter_reviews(pull)
    reviews = client.pull_request_reviews repo, pull.number, per_page: 100

    reviews.select { |r| r.user.login == username && date_range.cover?(r.submitted_at.to_datetime) }
  end

  def filter_commits(pull)
    commits = client.pull_request_commits repo, pull.number, per_page: 250
    commits = commits.reject { |n| (MERGE_COMMIT - n.commit.message.split).empty? }

    commits = commits.select { |c| c.author&.login == username }
    commits.select { |c| date_range.cover?(c.commit.author.date.to_datetime) }
  end
end

date_range = ARGV.fetch(0)
group_key  = ARGV.fetch(1)
groups     = YAML.load_file("#{__dir__}/projects.yml").slice(group_key)

groups.each do |_, projects|
  projects.each do |project|
    Octokit.configure do |c|
      c.api_endpoint = project.fetch("api_endpoint")
    end

    work = Work.new(date_range: date_range, repo: project.fetch("repo"), token: project.fetch("token"))

    puts  "-" * 50, "#{project.fetch("repo")}:", "-" * 50
    puts "*Reviewed:*"

    work.reviewed.each do |pull|
      puts "#{pull.title} [(##{pull.number})](#{pull.html_url})"
    end

    puts "\n*Worked on:*"

    work.worked_on.each do |pull, commits|
      puts "#{pull.title} [(##{pull.number})](#{pull.html_url})"

      commits.each do |commit|
        puts commit.commit.message
      end
    end
  end
end
