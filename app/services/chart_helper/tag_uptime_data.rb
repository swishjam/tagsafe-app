module ChartHelper
  class TagUptimeData
    def initialize(script_subscribers, time_ago = 1.day.ago)
      @script_subscribers = script_subscribers
      @time_ago = time_ago
    end

    def get_response_time_data!
      chart_data = []
      @script_subscribers.each do |script_subscriber|
        chart_data << { 
          name: script_subscriber.try_friendly_name,
          data: script_check_data(script_subscriber)
        }
      end
      chart_data
    end

    def script_check_data(script_subscriber)
      ScriptCheck.where(script_id: script_subscriber.script_id)
                  .newer_than(oldest_check_timestamp(script_subscriber))
                  .collect{ |check| [check.created_at, check.response_time_ms] }
    end

    def oldest_check_timestamp(script_subscriber)
      script_subscriber.created_at > @time_ago ? script_subscriber.created_at : @time_ago
    end
  end
end