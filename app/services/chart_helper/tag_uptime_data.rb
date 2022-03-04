module ChartHelper
  class TagUptimeData
    def initialize(tag_checks, start_time: 1.day.ago, end_time: Time.now)
      @tag_checks = tag_checks
      @start_time = start_time
      @end_time = end_time
    end

    def chart_data
      [
        response_time_data,
        success_data
      ]
    end

    private

    def response_time_data
      {
        name: 'Response Time (ms)',
        data: @tag_checks.collect{ |check| [check.created_at, check.response_time_ms] }
      }
    end
    
    def success_data
      {
        name: 'Failed Requests',
        data: @tag_checks.failed.collect{ |check| [check.created_at, check.response_code] }
      }
    end
  end
end