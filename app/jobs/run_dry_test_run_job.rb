class RunDryTestRunJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(functional_test, test_run)
    test_runner = LambdaModerator::FunctionalTestRunner.new(
      functional_test: functional_test,
      already_created_test_run: test_run,
      test_run_klass: DryTestRun,
      audit: nil
    )
    response = test_runner.send!
    if response.successful
      resp_body = response.response_body
      if resp_body['passed']
        test_run.passed!(resp_body['script_results'])
      else
        test_run.failed!(resp_body['errorMessage'] || resp_body['failure']['message'])
      end
    else
      raise StandardError, "FunctionalTestRunner returned error: #{response.inspect}"
    end
  end
end