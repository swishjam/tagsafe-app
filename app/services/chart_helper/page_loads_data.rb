module ChartHelper
  class PageLoadsData < Base
    def initialize(page_url:, page_load_performance_metric_types:, time_range:)
      @page_url = page_url
      @page_load_performance_metric_types = page_load_performance_metric_types
      @start_datetime = derived_start_time_from_time_range(time_range.to_sym)
      @formatted_chart_data = []
    end

    def chart_data
      @chart_data ||= begin
        get_performance_metrics
        # get_tagsafe_optimization_metrics
        @formatted_chart_data
      end
    end

    private

    def get_performance_metrics
      @page_url.page_load_performance_metrics
                .by_type(@page_load_performance_metric_types)
                .more_recent_than_or_equal_to(@start_datetime)
                .group_by(&:type).map do |type, metrics|
        @formatted_chart_data << { 
          name: type.constantize.friendly_name, 
          data: metrics.collect{ |metric| [metric.created_at, metric.value] },
          # yAxis: 0,
          # valueSuffix: 'ms',
        }
      end
    end

    def get_tagsafe_optimization_metrics
      page_loads = @page_url.page_loads.more_recent_than_or_equal_to(@start_datetime, timestamp_column: :tagsafe_consumer_received_at)
      @formatted_chart_data << { 
        name: '# tags optimized by TagsafeJS', 
        data: page_loads.collect{ |pl| [pl.tagsafe_consumer_received_at, pl.num_tags_optimized_by_tagsafe_js] },
        # yAxis: 1,
        # valueSuffix: 'tags',
      }
      @formatted_chart_data << { 
        name: '# tags not optimized by TagsafeJS', 
        data: page_loads.collect{ |pl| [pl.tagsafe_consumer_received_at, pl.num_tags_not_optimized_by_tagsafe_js] },
        # yAxis: 1,
        # valueSuffix: 'tags',
      }
    end
  end
end