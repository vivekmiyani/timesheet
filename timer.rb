#!/usr/bin/env ruby

require_relative "mac/core_graphics"

class Timer
  ONE_MINUTE = 60
  FIVE_MINUTES = 5 * 60

  attr_accessor \
    :activities,
    :ended_at,
    :started_at

  def initialize
    self.activities = []
  end

  def start
    throttle do
      seconds = idle_time

      if seconds <= FIVE_MINUTES
        # Work mode
        self.ended_at = Time.now - seconds
        self.started_at = ended_at if started_at.nil?
      else
        # Idle mode
        record_activity

        self.ended_at = nil
        self.started_at = nil
      end
    end
  end

  def stop
    record_activity

    puts "-" * 50
    puts "Started at\tEnded at\tTotal hours"
    puts "-" * 50

    total = 0.0
    activities.each do |activity|
      diff = activity.end - activity.begin
      total += diff

      puts "#{format_time(activity.begin)}\t#{format_time(activity.end)}\t#{diff / 3600}"
    end

    puts "-" * 50

    puts "Total: #{total / 3600} hours"
  end

  private

  def format_time(t)
    t.strftime "%F %T"
  end

  def idle_time
    Mac::CoreGraphics.idle_time
  end

  def record_activity
    return if !ended_at || !started_at

    range = started_at..ended_at
    activities << range

    puts "Worked for #{range}"
  end

  def throttle
    loop do
      yield

      sleep ONE_MINUTE
    end
  end
end

timer = Timer.new
Signal.trap("INT") { timer.stop; exit }

timer.start
