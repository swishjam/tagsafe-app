module ChartHelper
  class TagUptimeData
    def initialize(tag, tag_check_regions: [TagCheckRegion.US_EAST_1], start_time: 1.day.ago, end_time: Time.now)
      @tag = tag
      @tag_check_regions = tag_check_regions
      @start_time = start_time
      @end_time = end_time
    end

    def chart_data
      @chart_data ||= tag_checks_grouped_by_tag_check_region.map do |region_location, tag_checks_array|
        {
          name: region_location,
          data: tag_checks_array.map{ |tag_check| [tag_check.created_at, tag_check.response_time_ms] }
        }
      end
    end

    private

    def tag_checks_grouped_by_tag_check_region
      @tag_checks_grouped_by_tag_check_region ||= @tag.tag_checks.includes(:tag_check_region)
                                                                  .measured_uptime
                                                                  .by_tag_check_region(@tag_check_regions)
                                                                  .between(@start_time, @end_time)
                                                                  .group_by{ |tag_check| tag_check.tag_check_region.location }
    end
    
    # def response_time_data
    #   {
    #     name: 'Response Time (ms)',
    #     data: @tag_checks.collect{ |check| [check.created_at, check.response_time_ms] }
    #   }
    # end
    
    # def success_data
    #   {
    #     name: 'Failed Requests',
    #     data: @tag_checks.failed.collect{ |check| [check.created_at, check.response_code] }
    #   }
    # end
  end
end