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

    def initialize(payload_parser)
      @payload_parser = payload_parser
    end

    def consume!
      @payload_parser.performance_metrics.each do |metric_name, value|
        performance_metric_klass = PERFORMANCE_METRIC_KLASS_DICT[metric_name]
        if performance_metric_klass
          performance_metric_klass.create!(
            container: @payload_parser.container, 
            page_load: @payload_parser.page_load, 
            page_url: @payload_parser.page_load.page_url,
            value: value
          )
        else
          Rails.logger.warn "`TagsafeJsDataConsumer::PerformanceMetrics` received an unexpected performance metric: #{metric_name}. Skipping this attribute."
        end
      end
    end
  end
end