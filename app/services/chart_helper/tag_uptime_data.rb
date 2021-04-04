module ChartHelper
  class TagUptimeData
    def initialize(tags, time_ago = 1.day.ago)
      @tags = tags
      @time_ago = time_ago
    end

    def get_response_time_data!
      @tags.map do |tag|
        { 
          name: tag.try_friendly_name,
          data: tag_check_data(tag)
        }
      end
    end

    private
    
    def tag_check_data(tag)
      tag.tag_checks.more_recent_than(@time_ago).collect{ |check| [check.created_at, check.response_time_ms] }
    end
  end
end