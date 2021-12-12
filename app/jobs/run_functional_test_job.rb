class RunFunctionalTestJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(functional_test:, audit:, test_run_klass:)
    test_runner = LambdaModerator::FunctionalTestRunner.new(
      functional_test: functional_test,
      test_run_klass: test_run_klass,
      audit: audit
    )
    response = test_runner.send!
    if response.successful
      resp_body = response.response_body
      if resp_body['passed']
        test_runner.test_run.passed!(resp_body['script_results'])
      else
        test_runner.test_run.failed!(resp_body['failure']['message'])
      end
    else
      raise StandardError, "FunctionalTestRunner returned error: #{response.inspect}"
    end
  end
end