module ChartHelper
  class TagUptimeData
    def initialize(script_subscribers, time_ago = 1.day.ago)
      @script_subscribers = script_subscribers
      @time_ago = time_ago
    end

    def get_response_time_data!
      @script_subscribers.map do |script_subscriber|
        { 
          name: script_subscriber.try_friendly_name,
          data: script_check_data(script_subscriber)
        }
      end
    end

    def script_check_data(script_subscriber)
      ScriptCheck.where(script_id: script_subscriber.script_id)
                  .collect{ |check| [check.created_at, check.response_time_ms] }
                  # .more_recent_than(oldest_check_timestamp(script_subscriber))

    end

    def oldest_check_timestamp(script_subscriber)
      script_subscriber.created_at > @time_ago ? script_subscriber.created_at : @time_ago
    end
  end
end