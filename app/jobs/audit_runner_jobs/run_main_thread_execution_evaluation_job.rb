module AuditRunnerJobs
  class RunMainThreadExecutionEvaluationJob < ApplicationJob
    queue_as TagsafeQueue.CRITICAL
    
    def perform(main_thread_execution_audit_component, options = {})
      StepFunctionInvoker::MainThreadExecutionEvaluator.new(main_thread_execution_audit_component, options: options).send!
    end
  end
end