module AuditRunnerJobs
  class RunIndividualTestRun < ApplicationJob
    queue_as TagsafeQueue.CRITICAL
    
    def perform(test_run, options = {})
      StepFunctionInvoker::FunctionalTestRunner.new(test_run, options: options).send!
    end
  end
end