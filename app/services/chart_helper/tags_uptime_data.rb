module ChartHelper
  class TagsUptimeData
    def initialize(tags, start_time:, end_time:)
      @tags = tags
      @start_time = start_time
      @end_time = end_time
      # @time_ago = time_ago
    end

    def chart_data
      @tags.map do |tag|
        { 
          name: tag.try_friendly_name,
          data: tag_check_data(tag)
        }
      end
    end

    private
    
    def tag_check_data(tag)
      # tag.tag_checks.more_recent_than(@time_ago).collect{ |check| [check.created_at, check.response_time_ms] }
      tag.tag_checks.more_recent_than(@start_time)
                    .older_than(@end_time)
                    .order('created_at ASC')
                    .collect{ |check| [check.created_at, check.response_time_ms] }
    end
  end
end