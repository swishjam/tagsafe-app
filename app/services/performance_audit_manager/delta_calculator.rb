module PerformanceAuditManager
  class DeltaCalculator
    def initialize(results_with_tag:, results_without_tag:)
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
      @delta_results = {}
    end

    def calculate!
      metric_keys = @results_with_tag.keys
      metric_keys.each do |key|
        delta = @results_with_tag[key] - @results_without_tag[key]
        delta = delta < 0 ? 0 : delta
        @delta_results[key] = delta
      end
      @delta_results
    end
  end
end