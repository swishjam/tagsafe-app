module ChartHelper
  class TagsUptimeData < Base
    def initialize(tags, uptime_regions:, time_range:, use_uptime_region_as_plot_name: false)
      @tags = tags
      @uptime_regions = uptime_regions
      @start_datetime = derived_start_time_from_time_range(time_range)
      @use_uptime_region_as_plot_name = use_uptime_region_as_plot_name
    end

    def chart_data
      formatted_chart_data
    end

    private

    def formatted_chart_data
      chart_data = []
      @uptime_regions.each do |uptime_region|
        @tags.each do |tag|
          chart_data << { 
            name: @use_uptime_region_as_plot_name ? uptime_region.location : tag.try_friendly_name,
            data: uptime_check_data_for_region(tag, uptime_region)
          }
        end
      end
      chart_data
    end

    def cache_key(tag, uptime_region)
      "charts:#{tag.id}_#{uptime_region.aws_region_name}_#{@start_datetime.beginning_of_minute}"
    end
    
    def uptime_check_data_for_region(tag, uptime_region)
      Rails.cache.fetch(cache_key(tag, uptime_region), expires_in: 2.minutes) do
        Rails.logger.info "ChartHelper::TagsUptimeData Cache miss for cache key: #{cache_key(tag, uptime_region)}"
        tag.uptime_checks.by_uptime_region(uptime_region)
                    .more_recent_than(@start_datetime, timestamp_column: :"uptime_checks.executed_at")
                    .order('uptime_checks.created_at ASC')
                    .collect{ |check| [check.executed_at, check.response_time_ms] }
      end
    end
  end
end