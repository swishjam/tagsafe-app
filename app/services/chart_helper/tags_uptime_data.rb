module ChartHelper
  class TagsUptimeData < Base
    def initialize(tags, tag_check_regions:, time_range:, use_tag_check_region_as_plot_name: false)
      @tags = tags
      @tag_check_regions = tag_check_regions
      @start_datetime = derived_start_time_from_time_range(time_range)
      @use_tag_check_region_as_plot_name = use_tag_check_region_as_plot_name
    end

    def chart_data
      formatted_chart_data
    end

    private

    def formatted_chart_data
      chart_data = []
      @tag_check_regions.each do |tag_check_region|
        @tags.each do |tag|
          chart_data << { 
            name: @use_tag_check_region_as_plot_name ? tag_check_region.location : tag.try_friendly_name,
            data: tag_check_data_for_region(tag, tag_check_region)
          }
        end
      end
      chart_data
    end

    def cache_key(tag, tag_check_region)
      "#{tag.id}_#{tag_check_region.aws_region_name}_#{@start_datetime.beginning_of_minute}"
    end
    
    def tag_check_data_for_region(tag, tag_check_region)
      Rails.cache.fetch(cache_key(tag, tag_check_region), expires_in: 2.minutes) do
        Rails.logger.info "ChartHelper::TagsUptimeData Cache miss for cache key: #{cache_key(tag, tag_check_region)}"
        tag.tag_checks.by_tag_check_region(tag_check_region)
                    .more_recent_than(@start_datetime)
                    .order('tag_checks.created_at ASC')
                    .collect{ |check| [check.created_at, check.response_time_ms] }
      end
    end
  end
end