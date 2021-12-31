class RunIndividualTestRunJob < ApplicationJob
  queue_as :functional_tests_queue
  
  def perform(test_run, options = {})
    response = LambdaModerator::FunctionalTestRunner.new(test_run, options).send!
    resp_body = response.response_body
    update_attrs = { results: resp_body['script_results'], logs: resp_body['logs'] }
    if resp_body.dig('screen_recording', 's3_url')
      update_attrs[:puppeteer_recording_attributes] = {
        s3_url: resp_body['screen_recording']['s3_url'],
        ms_to_stop_recording: resp_body['screen_recording']['ms_to_stop']
      }
    end
    test_run.update!(update_attrs)
    if resp_body['passed']
      test_run.passed!
    else
      test_run.failed!(resp_body['errorMessage'] || resp_body.dig('failure', 'message') || resp_body['script_results'])
    end
    test_run.audit.try_completion! unless test_run.is_a?(DryTestRun)
  end
end