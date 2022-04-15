module StepFunctionResponses
  class TestRunResult < Base
    def process_results!
      update_test_run_with_response_info!
      if passed?
        test_run.passed!
      else
        test_run.failed!(
          message: error_message,
          type: error_type,
          trace: error_trace
        )
      end
    end

    def update_test_run_with_response_info!
      update_attrs = { 
        results: script_results, 
        script_execution_ms: script_execution_ms,
        logs: logs
      }
      if puppeteer_recording_attributes.present?
        update_attrs[:puppeteer_recording_attributes] = puppeteer_recording_attributes.formatted
      end
      test_run.update!(update_attrs)
    end

    def test_run
      @test_run ||= TestRun.find(request_payload['test_run_id'])
    end
    alias record test_run

    def puppeteer_recording_attributes
      @puppeteer_recording_attributes ||= StepFunctionResponses::TestRunResult::PuppeteerRecording.new(response_payload['screen_recording'])
    end

    def passed?
      @passed ||= response_payload['passed']
    end

    def script_results
      @script_results ||= response_payload['script_results']
    end

    def script_execution_ms
      @script_execution_ms ||= response_payload['script_execution_ms']
    end

    def logs
      @logs ||= response_payload['logs']
    end

    def error_message
      @error_message ||= response_payload['errorMessage'] || response_payload.dig('failure', 'message') || response_payload['script_results']
    end

    def error_type
      @error_type ||= response_payload['errorType']
    end

    def error_trace
      @error_trace ||= response_payload['trace']
    end
  end
end