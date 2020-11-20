module LighthouseManager
  class RawResultsHandler
    attr_accessor :average_results

    def initialize(audit:, lighthouse_audit_type_class:, array_of_results:, should_capture_metrics:)
      @audit = audit
      @lighthouse_audit_type_class = lighthouse_audit_type_class
      @array_of_results = array_of_results
      @should_capture_metrics = should_capture_metrics
      @sum_of_results = {}
      @average_results = {}
    end

    def capture_results!
      capture_lighthouse_results
      calculate_average
      self
    end

    private

    def capture_lighthouse_results
      @array_of_results.each do |lighthouse_result| 
        lighthouse_audit_result = capture_result_set(lighthouse_result)
        score = calculate_performance_score(lighthouse_result)
        lighthouse_audit_result.update(performance_score: score)
      end
    end

    def calculate_average
      @sum_of_results.each do |key, result_obj|
        @average_results[key] = {}
        @average_results[key]['value'] = result_obj['value']/@array_of_results.length
        @average_results[key]['score'] = result_obj['score']/@array_of_results.length unless result_obj['score'].nil?
        @average_results[key]['lighthouse_audit_metric_type'] = result_obj['lighthouse_audit_metric_type']
      end
    end

    def capture_result_set(result_set)
      lighthouse_audit = @lighthouse_audit_type_class.create(audit: @audit)
      result_set.each do |key, val|
        if key === 'lighthouse_report_url'
          capture_lighthouse_audit_file(val, lighthouse_audit)
        else
          metric_type = LighthouseAuditMetricType.find_by(key: key)
          if metric_type
            LighthouseAuditMetric.create(lighthouse_audit_id: lighthouse_audit.id, lighthouse_audit_metric_type: metric_type, result: val['value'], score: val['score']) if @should_capture_metrics
            add_result_to_sum(metric_type, val)
          else
            Rails.logger.info "Received unknown Lighthouse result: #{key}"
          end
        end
      end
      lighthouse_audit
    end

    def add_result_to_sum(metric_type, result_obj)
      @sum_of_results[metric_type.key] = @sum_of_results[metric_type.key] || {}
      @sum_of_results[metric_type.key]['value'] = (@sum_of_results[metric_type.key]['value'] || 0) + result_obj['value']
      @sum_of_results[metric_type.key]['score'] = (@sum_of_results[metric_type.key]['score'] || 0) + result_obj['score'] unless result_obj['score'].nil?
      @sum_of_results[metric_type.key]['lighthouse_audit_metric_type'] = metric_type
    end

    def calculate_performance_score(result_obj)
      LighthouseManager::PerformanceScoreCalculator.new(
        first_contentful_paint_score: result_obj['first-contentful-paint']['score'],
        speed_index_score: result_obj['speed-index']['score'],
        largest_contentful_paint_score: result_obj['largest-contentful-paint']['score'],
        interactive_score: result_obj['interactive']['score'],
        total_blocking_time_score: result_obj['total-blocking-time']['score'],
        cumulative_layout_shift_score: result_obj['cumulative-layout-shift']['score']
      ).calculate!
    end

    def capture_lighthouse_audit_file(lighthouse_audit_file_url, lighthouse_audit)
      file_name = [@audit.id, lighthouse_audit.id, Time.now.to_i].join('-')
      html_file = LighthouseManager::ReportHtmlHandler.new(lighthouse_audit_file_url, file_name).write_report_to_local_file
      lighthouse_audit.update(report_html: { io: File.open(html_file), filename: "#{file_name}.html" })
    end
  end
end