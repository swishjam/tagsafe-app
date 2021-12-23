class RunFunctionalTestSuiteForAuditJob < ApplicationJob
  queue_as :functional_tests_queue

  def perform(audit)
    audit.tag.functional_tests.each{ |functional_test| run_functional_test(audit, functional_test) }
  end

  def run_functional_test(audit, functional_test)
    test_runner = LambdaModerator::FunctionalTestRunner.new(
      functional_test: functional_test,
      test_run_klass: TestRunWithTag,
      audit: audit
    )
    response = test_runner.send!
    if response.successful
      resp_body = response.response_body
      if resp_body['passed']
        test_runner.test_run.passed!(
          resp_body['script_results'], 
          logs: resp_body['logs'],
          screenshots: resp_body['screenshots'],
          puppeteer_recording: { 
            s3_url: resp_body['screen_recording']['s3_url'], 
            ms_to_stop_recording: resp_body['screen_recording']['ms_to_stop'] 
          }
        )
      else
        test_runner.test_run.failed!(
          resp_body['errorMessage'] || resp_body['failure']['message'] || resp_body['script_results'],
          logs: resp_body['logs'],
          screenshots: resp_body['screenshots'],
          puppeteer_recording: { 
            s3_url: resp_body['screen_recording']['s3_url'], 
            ms_to_stop_recording: resp_body['screen_recording']['ms_to_stop'] 
          }
        )
      end
      audit.try_completion!
    else
      raise StandardError, "FunctionalTestRunner returned error: #{response.inspect}"
    end
  end
end