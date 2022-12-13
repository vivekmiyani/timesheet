#!/usr/bin/env ruby

class Timer
  THRESHOLD = 5 * 60 # 5 minutes

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

      if seconds <= THRESHOLD
        # Work mode
        self.ended_at = Time.now - seconds
        self.started_at = ended_at if started_at.nil?
      else
        # Idle mode
        record_activity(started_at..ended_at) if ended_at && started_at

        self.ended_at = nil
        self.started_at = nil
      end
    end
  end

  def display_activities
    puts "Saving!"

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
    ns = `ioreg -c IOHIDSystem | grep HIDIdleTime`.split(" = ").last.to_f

    ns / 1000000000
  end

  def record_activity(range)
    activities << range

    puts "Worked for #{range}"
  end

  def throttle
    loop do
      yield

      sleep THRESHOLD
    end
  end
end

timer = Timer.new
Signal.trap("INT")  { timer.display_activities; exit }

timer.start
