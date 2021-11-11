module PerformanceAuditManager
  class AuditPrecisionScorer
    MEASURABLE_PERF_AUDIT_ATTRS = %i[dom_complete dom_interactive first_contentful_paint script_duration layout_duration task_duration]
    attr_accessor :with_tag_scores, :without_tag_scores

    def initialize(audit)
      @audit = audit
    end

    # def calculate_precision
    #   (tagsafe_score_std_dev(individual_performance_audits_with_tag) + tagsafe_score_std_dev(individual_performance_audits_without_tag)) / 2
    # end


    def calculate_standard_deviation_precision
      ensure_successful_audit
      calculate_std_dev_for_each_attribute
    end

    def calculate_variance_precision
      ensure_successful_audit
      calculate_variance_for_each_attribute
    end

    private

    def ensure_successful_audit
      raise InvalidAudit, "Audit must be completed and successfull in order to score its accuracy. It is currently #{@audit.state}" if !@audit.performance_audit_successful?
    end

    def calculate_std_dev_for_each_attribute
      @with_tag_std_devs = {}
      @without_tag_std_devs = {}
      MEASURABLE_PERF_AUDIT_ATTRS.each do |attr|
        @with_tag_std_devs[attr] = Statistics.std_dev(individual_performance_audits_with_tag.collect(&:"#{attr}"))
        @without_tag_std_devs[attr] = Statistics.std_dev(individual_performance_audits_without_tag.collect(&:"#{attr}"))
      end
    end

    def calculate_variance_for_each_attribute
      @with_tag_variance = {}
      @without_tag_variance = {}
      MEASURABLE_PERF_AUDIT_ATTRS.each do |attr|
        @with_tag_variance[attr] = Statistics.variance(individual_performance_audits_with_tag.collect(&:"#{attr}"))
        @without_tag_variance[attr] = Statistics.variance(individual_performance_audits_without_tag.collect(&:"#{attr}"))
      end
    end

    # def calculate_performance_audit_attribute_scores
    #   @with_tag_scores = {}
    #   @without_tag_scores = {}
    #   MEASURABLE_PERF_AUDIT_ATTRS.each do |attr| 
    #     @with_tag_scores[attr] = average_deviation_for_perf_audit_attr(individual_performance_audits_with_tag, attr)
    #     @without_tag_scores[attr] = average_deviation_for_perf_audit_attr(individual_performance_audits_without_tag, attr)
    #   end
    # end

    # def average_all_scores
    #   total_score = 0.0
    #   with_tag_scores.each{ |_attr, score| total_score += score  }
    #   without_tag_scores.each{ |_attr, score| total_score += score  }
    #   total_score / (with_tag_scores.count + without_tag_scores.count)
    # end

    # def average_deviation_for_perf_audit_attr(perf_audits, attr)
    #   result_set = perf_audits.collect(&:"#{attr}")
    #   mean = Statistics.mean(result_set)
    #   absolute_deviations = result_set.map{ |result| (result - mean).abs }
    #   absolute_deviations.inject(&:+) / result_set.count
    # end

    def individual_performance_audits_with_tag
      @individual_performance_audits_with_tag ||= @audit.individual_performance_audits_with_tag
    end

    def individual_performance_audits_without_tag
      @individual_performance_audits_without_tag ||= @audit.individual_performance_audits_without_tag
    end
  end
end