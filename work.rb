#!/usr/bin/env ruby

# frozen_string_literal: true

require "faraday"

class Work
  attr_reader \
    :date_range,
    :token

  def initialize(date_range:, token:)
    @date_range = parse_date_range(date_range)
    @token = token
  end

  def print_summary
    search.each do |(repo, title), work|
      puts "-" * 50, "#{repo}:", "-" * 50

      puts title

      work[:commits].each do |i|
        puts "- #{i}"
      end

      puts "- Reviewed" if work[:reviewed]

      puts "- Merged" if work[:merged]
    end
  end

  private

  def parse_date_range(date_range)
    zone = DateTime.now.zone
    date_range = date_range.split("..")

    from = "#{date_range.first}T00:00:00#{zone}"
    to = "#{date_range.last}T23:59:59#{zone}"

    DateTime.parse(from)..DateTime.parse(to)
  end

  def request(query:, variables:)
    body = { query: query, variables: variables }.to_json
    headers = { Authorization: "Bearer #{token}" }

    body = Faraday.post("https://api.github.com/graphql", body, headers).body

    JSON.parse(body)
  end

  def search # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    repositories = viewer[:repositories].map { |i| "repo:#{i}" }.join(" ")

    variables = {
      query: "type:pr updated:>=#{date_range.begin} #{repositories}",
      type: "ISSUE"
    }

    response = request(query: search_query, variables: variables)["data"]["search"]["nodes"]

    response.each_with_object({}) do |node, object|
      commits = node["commits"]["nodes"].find_all do |commit|
        commit.dig("commit", "author", "user", "login") == viewer[:login] && date_range.cover?(DateTime.parse(commit["commit"]["committedDate"])) # rubocop:disable Layout/LineLength
      end
      commits = commits.map { |i| i["commit"]["message"] }

      reviewed = node["latestReviews"]["nodes"].find_all do |review|
        review.dig("author", "login") == viewer[:login] && date_range.cover?(DateTime.parse(review["submittedAt"]))
      end.length.positive?

      merged = node.dig("mergedBy", "login") == viewer[:login] && date_range.cover?(DateTime.parse(node["mergedAt"]))

      key = [node["repository"]["nameWithOwner"], node["title"]]

      if commits.length.positive? || reviewed || merged
        object[key] = { commits: commits, reviewed: reviewed, merged: merged }
      end
    end
  end

  def search_query
    <<~GQL
      query search($query: String!, $type: SearchType!) {
        search(last: 100, query: $query, type: $type) {
          nodes {
            ... on PullRequest {
              commits(last: 250) {
                nodes {
                  commit {
                    committedDate
                    message
                    author {
                      user {
                        login
                      }
                    }
                  }
                }
              }
              latestReviews(last: 100) {
                nodes {
                  author {
                    login
                  }
                  submittedAt
                }
              }
              mergedAt
              mergedBy {
                login
              }
              repository {
                nameWithOwner
              }
              title
            }
          }
        }
      }
    GQL
  end

  def viewer
    @viewer ||= begin
      response = request(query: viewer_query, variables: {})["data"]["viewer"]

      {
        login: response["login"],
        repositories: response["repositoriesContributedTo"]["nodes"].map { |i| i["nameWithOwner"] }
      }
    end
  end

  def viewer_query
    <<~GQL
      query viewer {
        viewer {
          login
          repositoriesContributedTo(
            first: 100
            orderBy: { direction: DESC, field: PUSHED_AT }
            includeUserRepositories: true
          ) {
            nodes {
              nameWithOwner
            }
          }
        }
      }
    GQL
  end
end

date_range = ARGV.fetch(0)
token = File.read("#{ENV['HOME']}/.timesheet-token")

work = Work.new(date_range: date_range, token: token)

work.print_summary
