module LighthouseManager
  class AverageResultsHandler
    def initialize(audit:, lighthouse_audit_type_class:, average_results:)
      @audit = audit
      @lighthouse_audit_type_class = lighthouse_audit_type_class
      @average_results = average_results
    end

    def capture_results!
      capture_average_results
      score = calculate_performance_score
      lighthouse_audit.update(performance_score: score)
    end

    private

    def lighthouse_audit
      @lighthouse_audit ||= @lighthouse_audit_type_class.create(audit: @audit)
    end

    def capture_average_results
      @average_results.each do |key, val|
        LighthouseAuditMetric.create(
          lighthouse_audit: lighthouse_audit,
          lighthouse_audit_metric_type: val['lighthouse_audit_metric_type'], 
          result: val['value'], 
          score: val['score']
        )
      end
    end

    def calculate_performance_score
      LighthouseManager::PerformanceScoreCalculator.new(
        first_contentful_paint_score: @average_results['first-contentful-paint']['score'],
        speed_index_score: @average_results['speed-index']['score'],
        largest_contentful_paint_score: @average_results['largest-contentful-paint']['score'],
        interactive_score: @average_results['interactive']['score'],
        total_blocking_time_score: @average_results['total-blocking-time']['score'],
        cumulative_layout_shift_score: @average_results['cumulative-layout-shift']['score']
      ).calculate!
    end
  end
end