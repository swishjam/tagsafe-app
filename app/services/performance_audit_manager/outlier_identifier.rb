module PerformanceAuditManager
  class OutlierIdentifier
    def initialize(audit, metric: :tagsafe_score, sensitivity: :high)
      @audit = audit
      @metric = metric
      @sensitivity = sensitivity
      @outliers_marked = DeltaPerformanceAudit.none
    end

    def find_outliers!
      @outliers ||= begin
        return DeltaPerformanceAudit.none unless has_minimum_delta_performance_audits_to_identify_outliers?
        delta_performance_audits.where("#{@metric} < ? OR #{@metric} > ?", outlier_helper.bottom_fence, outlier_helper.top_fence)
      end
    end

    def num_outliers
      find_outliers!.count
    end

    def mark_outliers!
      find_outliers!.update_all(is_outlier: true)
      @outliers_marked = find_outliers!
    end

    def un_mark_any_marked_outliers!
      return unless @outliers_marked
      @outliers_marked.update_all(is_outlier: false)
      @outliers_marked = DeltaPerformanceAudit.none
    end

    def outliers_marked?
      @outliers_marked.any?
    end

    def has_minimum_delta_performance_audits_to_identify_outliers?
      delta_performance_audits.count > 6
    end

    private
    
    def outlier_helper
      @outlier_helper ||= MathHelpers::OutlierHelper.new(data_points_for_outlier_detection, sensitivity: @sensitivity)
    end

    def data_points_for_outlier_detection
      @tagsafe_scores ||= delta_performance_audits.collect(&:"#{@metric}")
    end

    def delta_performance_audits
      @delta_performance_audits ||= @audit.delta_performance_audits.not_outliers
    end
  end
end