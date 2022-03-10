module AuditRunnerJobs
  class RunIndividualTestRun < ApplicationJob
    def perform(test_run, options = {})
      LambdaFunctionInvoker::FunctionalTestRunner.new(test_run, options: options).send!
    end
  end
end