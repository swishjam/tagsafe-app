module LighthouseManager
  class DeltaResultsHandler
    def initialize(audit:, average_results_with_tag:, average_results_without_tag:)
      @audit = audit
      @average_results_with_tag = average_results_with_tag
      @average_results_without_tag = average_results_without_tag
    end

    def capture_results!
      capture_results_delta
      score = calculate_performance_score_delta
      lighthouse_audit.update(performance_score: score)
    end

    private

    def lighthouse_audit
      @lighthouse_audit ||= DeltaLighthouseAudit.create(audit: @audit)
    end

    def capture_results_delta
      @average_results_without_tag.each do |key, val|
        val_diff = @average_results_with_tag[key]['value'] - val['value']
        score_diff = val['score'].nil? ? nil : @average_results_with_tag[key]['score'] - val['score']
        LighthouseAuditMetric.create(lighthouse_audit_id: lighthouse_audit.id, lighthouse_audit_metric_type: val['lighthouse_audit_metric_type'], result: val_diff, score: score_diff)
      end
    end

    def calculate_performance_score_delta
      LighthouseManager::PerformanceScoreCalculator.new(
        first_contentful_paint_score: @average_results_with_tag['first-contentful-paint']['score'] - @average_results_without_tag['first-contentful-paint']['score'],
        speed_index_score: @average_results_with_tag['speed-index']['score'] - @average_results_without_tag['speed-index']['score'],
        largest_contentful_paint_score: @average_results_with_tag['largest-contentful-paint']['score'] - @average_results_without_tag['largest-contentful-paint']['score'], 
        interactive_score: @average_results_with_tag['interactive']['score'] - @average_results_without_tag['interactive']['score'], 
        total_blocking_time_score: @average_results_with_tag['total-blocking-time']['score'] - @average_results_without_tag['total-blocking-time']['score'],
        cumulative_layout_shift_score: @average_results_with_tag['cumulative-layout-shift']['score'] - @average_results_without_tag['cumulative-layout-shift']['score']
      ).calculate!
    end
  end
end