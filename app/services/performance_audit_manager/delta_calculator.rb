module PerformanceAuditManager
  class DeltaCalculator
    def initialize(results_with_tag:, results_without_tag:)
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
      @delta_results = {}
    end

    def calculate!
      metric_keys = @results_with_tag.keys
      metric_keys.each{ |key| @delta_results[key] = @results_with_tag[key] - @results_without_tag[key] }
      @delta_results
    end
  end
end