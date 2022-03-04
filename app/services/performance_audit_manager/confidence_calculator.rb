module PerformanceAuditManager
  class ConfidenceCalculator
    def initialize(audit)
      @audit = audit
    end

    def tagsafe_score_confidence_range(round = true)
      # return Float::INFINITY if non_outlier_tagsafe_scores.none?
      @tagsafe_score_confidence_range ||= MathHelpers::SmallSampleConfidenceRange.new(non_outlier_tagsafe_scores).range(round)
    end

    def tagsafe_score_confidence_plus_minus(round = true)
      return Float::INFINITY if non_outlier_tagsafe_scores.none?
      @tagsafe_score_confidence_plus_minus ||= MathHelpers::SmallSampleConfidenceRange.new(non_outlier_tagsafe_scores).plus_minus(round)
    end

    def performance_audit_with_tag_confidence_range_for_metric(metric)
      return nil if successful_performance_audits_with_tag.none?
      metrics = successful_performance_audits_with_tag.completed_successfully.map{ |ipa| ipa.send(metric) }
      MathHelpers::SmallSampleConfidenceRange.new(metrics).range
    end

    def performance_audit_without_tag_confidence_range_for_metric(metric)
      return nil if successful_performance_audits_without_tag.none?
      metrics = successful_performance_audits_without_tag.completed_successfully.map{ |ipa| ipa.send(metric) }
      MathHelpers::SmallSampleConfidenceRange.new(metrics).range
    end

    def performance_audit_with_tag_confidence_plus_minus_for_metric(metric)
      return nil if successful_performance_audits_with_tag.none?
      metrics = successful_performance_audits_with_tag.completed_successfully.map{ |ipa| ipa.send(metric) }
      MathHelpers::SmallSampleConfidenceRange.new(metrics).plus_minus
    end

    def performance_audit_without_tag_confidence_plus_minus_for_metric(metric)
      return nil if successful_performance_audits_without_tag.none?
      metrics = successful_performance_audits_without_tag.completed_successfully.map{ |ipa| ipa.send(metric) }
      MathHelpers::SmallSampleConfidenceRange.new(metrics).plus_minus
    end

    def performance_audit_with_tag_std_dev_for(metric)
      return nil if successful_performance_audits_with_tag.none?
      MathHelpers::Statistics.std_dev(successful_performance_audits_with_tag.map{ |ipa| ipa.send(metric) }).round(2)
    end
  
    def performance_audit_without_tag_std_dev_for(metric)
      return nil if successful_performance_audits_without_tag.none?
      MathHelpers::Statistics.std_dev(successful_performance_audits_without_tag.map{ |ipa| ipa.send(metric) }).round(2)
    end
  
    def performance_audit_with_tag_variance_for(metric)
      return nil if successful_performance_audits_with_tag.none?
      MathHelpers::Statistics.variance(successful_performance_audits_with_tag.map{ |ipa| ipa.send(metric) }).round(2)
    end
  
    def performance_audit_without_tag_variance_for(metric)
      return nil if successful_performance_audits_without_tag.none?
      MathHelpers::Statistics.variance(successful_performance_audits_without_tag.map{ |ipa| ipa.send(metric) }).round(2)
    end

    private

    def non_outlier_tagsafe_scores
      @non_outlier_tagsafe_scores ||= @audit.delta_performance_audits.not_outliers.where(type: [MedianDeltaPerformanceAudit.to_s, IndividualDeltaPerformanceAudit.to_s]).collect(&:tagsafe_score)
    end

    def successful_performance_audits_with_tag
      @successful_performance_audits_with_tag ||= @audit.individual_and_median_performance_audits_with_tag.completed_successfully
    end

    def successful_performance_audits_without_tag
      @successful_performance_audits_without_tag ||= @audit.individual_and_median_performance_audits_without_tag.completed_successfully
    end
  end
end