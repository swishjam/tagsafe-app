module AuditRunnerJobs
  class RunIndividualTestRun < ApplicationJob
    queue_as :functional_tests_queue
    
    def perform(test_run, options = {})
      response = LambdaModerator::FunctionalTestRunner.new(test_run, options).send!
      resp_body = response.response_body
      update_test_run_with_response_body(test_run, resp_body)
      if resp_body['passed']
        test_run.passed!
      else
        test_run.failed!(
          message: resp_body['errorMessage'] || resp_body.dig('failure', 'message') || resp_body['script_results'],
          type: resp_body['errorType'],
          trace: resp_body['trace']
        )
      end
      test_run.audit.functional_tests_completed! if !test_run.is_a?(DryTestRun) && test_run.audit.functional_tests_completed?
    end

    def update_test_run_with_response_body(test_run, response_body)
      update_attrs = { 
        results: response_body['script_results'], 
        script_execution_ms: response_body['script_execution_ms'],
        logs: response_body['logs'] ,
      }
      if response_body.dig('screen_recording', 's3_url') || response_body.dig('screen_recording', 'failed_to_capture')
        s3_url_value = response_body['screen_recording']['s3_url'] || PuppeteerRecording::FAILED_TO_CAPTURE_S3_URL_VALUE
        update_attrs[:puppeteer_recording_attributes] = {
          s3_url: s3_url_value,
          ms_to_stop_recording: response_body['screen_recording']['ms_to_stop'],
          ms_available_to_stop_within: response_body['screen_recording']['stop_ms_threshold']
        }
      end
      test_run.update!(update_attrs)
    end
  end
end