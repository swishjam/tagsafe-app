module LambdaFunctionInvoker
  class FunctionalTestRunner < Base
    lambda_service 'functional-tests'
    lambda_function 'run-test'

    attr_accessor :test_run

    def initialize(test_run, options: {}, attempt_number: 1)
      @test_run = test_run
      @options = options
      @executed_lambda_function_parent = test_run
      @attempt_number = attempt_number
      @receiver_job_queue = test_run.audit&.initiated_by_user? ? :user_waiting : :default
    end

    # def on_lambda_failure(_error_message)
    #   test_run.failed!(message: "An unexpected error occurred.")
    #   unless @attempt_number >= 3
    #     self.class.new(
    #       TestRun.create!(
    #         functional_test: test_run.functional_test, 
    #         type: test_run.type, 
    #         audit: test_run.associated_audit, 
    #         test_run_id_retried_from: test_run.test_run_retried_from&.id, 
    #         puppeteer_script_ran: test_run.puppeteer_script, 
    #         expected_results: test_run.expected_results, 
    #         enqueued_at: Time.now
    #       ),
    #       options: @options,
    #       attempt_number: @attempt_number + 1
    #     ).send!
    #   end
    # end

    def request_payload
      { 
        test_run_id: test_run.id,
        puppeteer_script: test_run.puppeteer_script_ran,
        expected_results: test_run.expected_results,
        first_party_url: domain.url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: allowed_request_urls,
        max_script_exeuction_ms: @options[:max_script_exeuction_ms] || Flag.flag_value_for_objects(functional_test, domain, slug: 'max_functional_test_script_execution_ms').to_i,
        enable_screen_recording: (@options[:enable_screen_recording] == nil ? true : @options[:enable_screen_recording]).to_s, # true by default
        include_screen_recording_on_passing_script: (@options[:include_screen_recording_on_passing_script] || false).to_s # false by default
      }
    end

    def script_injection_rules
      return [] unless test_run.is_a?(TestRunWithTag)
      return [] unless audit.run_on_tagsafe_tag_version?
      [{ url:  tag_version.js_file_url, load_type: 'async' }]
    end

    def allowed_request_urls
      patterns = domain.non_third_party_url_patterns.collect(&:pattern)
      patterns << tag.url_based_on_preferences if audit.run_on_live_tag? && test_run.is_a?(TestRunWithTag)
      patterns
    end

    def functional_test
      @functional_test ||= test_run.functional_test
    end

    def audit
      @audit ||= test_run.audit
    end

    def domain
      @domain ||= functional_test.domain
    end

    def tag_version
      @tag_version ||= audit.tag_version
    end

    def tag
      @tag ||= audit.tag
    end
  end
end