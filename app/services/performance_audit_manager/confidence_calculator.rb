module PerformanceAuditManager
  class ConfidenceCalculator
    def initialize(audit, aggregate_results_for_all_audits_on_tag_version: false)
      @audit = audit
      @aggregate_results_for_all_audits_on_tag_version = aggregate_results_for_all_audits_on_tag_version
    end

    def tagsafe_score_confidence_range(round = true)
      @tagsafe_score_confidence_range ||= MathHelpers::SmallSampleConfidenceRange.new(all_tagsafe_scores_generated).range(round)
    end

    def tagsafe_score_confidence_plus_minus(round = true)
      @tagsafe_score_confidence_plus_minus ||= MathHelpers::SmallSampleConfidenceRange.new(all_tagsafe_scores_generated).plus_minus(round)
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

    def all_tagsafe_scores_generated
      @all_tagsafe_scores_generated ||= @aggregate_results_for_all_audits_on_tag_version ? 
                                          @audit.tag_version.audits.map{ |audit| audit.delta_performance_audits.collect(&:tagsafe_score) }.flatten :
                                          @audit.delta_performance_audits.collect(&:tagsafe_score)
    end

    def successful_performance_audits_with_tag
      @successful_performance_audits_with_tag ||= begin
        if @aggregate_results_for_all_audits_on_tag_version
          @audit.tag_version.audits.map{ |audit| audit.individual_and_median_performance_audits_with_tag.completed_successfully }.flatten
        else
          @audit.individual_and_median_performance_audits_with_tag.completed_successfully
        end
      end
    end

    def successful_performance_audits_without_tag
      @successful_performance_audits_without_tag ||= begin
        if @aggregate_results_for_all_audits_on_tag_version
          @audit.tag_version.audits.map{ |audit| audit.individual_and_median_performance_audits_without_tag.completed_successfully }.flatten
        else
          @audit.individual_and_median_performance_audits_without_tag.completed_successfully
        end
      end
    end
  end
end