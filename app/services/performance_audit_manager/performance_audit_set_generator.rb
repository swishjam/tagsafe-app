module PerformanceAuditManager
  class PerformanceAuditSetGenerator
    attr_accessor :performance_audit_with_tag, :performance_audit_without_tag

    def initialize(audit)
      @audit = audit
    end

    def generate_performance_audit_set!
      generate_performance_audit_with_tag!
      generate_performance_audit_without_tag!
      # generate_delta_performance_audit!
    end

    private

    def generate_performance_audit_with_tag!
      return if @audit.performance_audit_failed?
      @performance_audit_with_tag ||= run_performance_audit!(IndividualPerformanceAuditWithTag)
    end

    def generate_performance_audit_without_tag!
      return if @audit.performance_audit_failed?
      @performance_audit_without_tag ||= run_performance_audit!(IndividualPerformanceAuditWithoutTag)
    end

    # def generate_delta_performance_audit!
    #   return if @audit.performance_audit_failed?
    #   PerformanceAuditManager::DeltaPerformanceAuditCreator.new(
    #     performance_audit_with_tag: performance_audit_with_tag,
    #     performance_audit_without_tag: performance_audit_without_tag,
    #   ).create_delta_performance_audit!
    # end

    def run_performance_audit!(performance_audit_klass)
      return if @audit.performance_audit_failed?
      performance_auditer = LambdaFunctionInvoker::PerformanceAuditer.new(audit: @audit, performance_audit_klass: performance_audit_klass)
      response = performance_auditer.send!
      performance_audit_failed!(performance_auditer.individual_performance_audit, response.error) unless response.successful
    end

    def performance_audit_failed!(performance_audit, error)
      performance_audit.error!(error)
      if @audit.reached_maximum_failed_performance_audits?
        @audit.performance_audit_error!("Reached maximum failed performance audits of #{audit.maximum_individual_performance_audit_attempts}")
      else
        raise 'Performance audit failed! Need to implement retries now....'
        # run_performance_audit!(performance_audit.class)
      end
    end

    # def new_performance_auditer(performance_audit_klass)
    #   lambda_sender = LambdaFunctionInvoker::PerformanceAuditer.new(audit: @audit, performance_audit_klass: performance_audit_klass)
    #   lambda_sender.set_other_performance_audit_for_delta_calculation(performance_auditer_with_tag.individual_performance_audit)
    #   lambda_sender
    # end
  end
end