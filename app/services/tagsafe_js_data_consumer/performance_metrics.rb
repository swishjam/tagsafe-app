module TagsafeJsDataConsumer
  class PerformanceMetrics
    PERFORMANCE_METRIC_KLASS_DICT = {
      'dom_complete' => DomCompletePerformanceMetric,
      'dom_interactive' => DomInteractivePerformanceMetric,
      'first_contentful_paint' => FirstContentfulPaintPerformanceMetric,
      'time_to_first_byte' => TimeToFirstBytePerformanceMetric,
      'total_blocking_time' => TotalBlockingTimePerformanceMetric,
      'third_party_js_network_time' => ThirdPartyJsNetworkTimePerformanceMetric
    }

    def initialize(container:, page_load:, performance_metrics:)
      @container = container
      @page_load = page_load
      @performance_metrics_hash = performance_metrics
    end

    def consume!
      @performance_metrics_hash.each do |metric_name, value|
        performance_metric_klass = PERFORMANCE_METRIC_KLASS_DICT[metric_name]
        if performance_metric_klass
          performance_metric_klass.create!(
            container: @container, 
            page_load: @page_load, 
            page_url: @page_load.page_url,
            value: value
          )
        else
          Rails.logger.warn "`TagsafeJsDataConsumer::PerformanceMetrics` received an unexpected performance metric: #{metric_name}. Skipping this attribute."
        end
      end
    end
  end
end