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
        test_run.passed!(
          resp_body['script_results'], 
          logs: resp_body['logs'],
          screenshots: resp_body['screenshots'] || [],
          puppeteer_recording: { 
            s3_url: resp_body.dig('screen_recording', 's3_url'), 
            ms_to_stop_recording: resp_body.dig('screen_recording', 'ms_to_stop') 
          }
        )
      else
        test_run.failed!(
          resp_body['errorMessage'] || resp_body.dig('failure', 'message') || resp_body['script_results'], 
          logs: resp_body['logs'],
          screenshots: resp_body['screenshots'] || [],
          puppeteer_recording: { 
            s3_url: resp_body.dig('screen_recording', 's3_url'), 
            ms_to_stop_recording: resp_body.dig('screen_recording', 'ms_to_stop')
          }
        )
      end
    else
      raise StandardError, "FunctionalTestRunner returned error: #{response.inspect}"
    end
  end
end