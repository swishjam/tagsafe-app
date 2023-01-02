module ChartHelper
  class PageLoadsData < Base
    def initialize(page_url:, page_load_performance_metric_types:, time_range:)
      @page_url = page_url
      @page_load_performance_metric_types = page_load_performance_metric_types
      @start_datetime = derived_start_time_from_time_range(time_range.to_sym)
    end

    def chart_data(include_performance_metrics: true, include_tagsafe_optimizations: false)
      Rails.cache.fetch([
        @page_url,
        @page_load_performance_metric_types.join('-'),
        @start_datetime,
        include_performance_metrics,
        include_tagsafe_optimizations
      ].join('_'), expires_in: 1.minute) do
        formatted_chart_data = []
        formatted_chart_data << get_performance_metrics if include_performance_metrics
        formatted_chart_data << get_tagsafe_optimization_metrics if include_tagsafe_optimizations
        formatted_chart_data.flatten!
      end
    end

    private

    def get_performance_metrics
      @page_url.page_load_performance_metrics
                .includes(:page_load)
                .by_type(@page_load_performance_metric_types)
                .more_recent_than_or_equal_to(@start_datetime)
                .group_by(&:type).map do |type, metrics|
        { 
          name: type.constantize.friendly_name, 
          data: metrics.collect{ |metric| [metric.page_load.page_load_ts, metric.value] },
          yAxis: 0,
          # valueSuffix: 'ms',
        }
      end
    end

    def get_tagsafe_optimization_metrics
      page_loads = @page_url.page_loads.more_recent_than_or_equal_to(@start_datetime, timestamp_column: :tagsafe_consumer_received_at)
      [{ 
        name: '# tags optimized by TagsafeJS', 
        data: page_loads.collect{ |pl| [pl.tagsafe_consumer_received_at, pl.num_tags_optimized_by_tagsafe_js] },
        yAxis: 0,
        # valueSuffix: 'tags',
      },
      { 
        name: '# tags not optimized by TagsafeJS', 
        data: page_loads.collect{ |pl| [pl.tagsafe_consumer_received_at, pl.num_tags_not_optimized_by_tagsafe_js] },
        yAxis: 0,
        # valueSuffix: 'tags',
      }]
    end
  end
end