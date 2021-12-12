class RunDryTestRunJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(functional_test, test_run)
    test_runner = LambdaModerator::FunctionalTestRunner.new(
      functional_test: functional_test,
      test_run_klass: nil,
      domain: functional_test.domain,
      test_run: test_run,
      tag_version: nil,
      audit: nil
    )
    response = test_runner.send!
    if response.successful
      resp_body = response.response_body
      if resp_body['passed']
        test_run.passed!(resp_body['script_results'])
      else
        test_run.failed!(resp_body['failure']['message'])
      end
    else
      raise StandardError, "FunctionalTestRunner returned error: #{response.inspect}"
    end
  end
end