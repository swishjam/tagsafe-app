module AuditRunnerJobs
  class RunJsUsageCalculationJob < ApplicationJob
    queue_as TagsafeQueue.CRITICAL
    
    def perform(js_usage_audit_component)
      StepFunctionInvoker::JsCoverageCalculator.new(js_usage_audit_component).send!
    end
  end
end