module StepFunctionInvoker
  class FunctionalTestRunner < Base
    self.step_function_name = 'run-functional-test'
    self.results_consumer_klass = StepFunctionResponses::TestRunResult

    attr_accessor :test_run

    def initialize(test_run, options: {})
      @test_run = test_run
      @options = options
      @receiver_job_queue = test_run.is_a?(DryTestRun) ? TagsafeQueue.CRITICAL : test_run.audit.initiated_by_user? ? TagsafeQueue.CRITICAL : nil
    end

    def executed_step_function_parent
      test_run
    end

    def request_payload
      { 
        test_run_id: test_run.id,
        puppeteer_script: test_run.puppeteer_script_ran,
        expected_results: test_run.expected_results,
        first_party_url: domain.url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: allowed_request_urls,
        max_script_execution_ms: @options[:max_script_execution_ms] || Flag.flag_value_for_objects(functional_test, domain, slug: 'max_functional_test_script_execution_ms').to_i,
        enable_screen_recording: (@options[:enable_screen_recording] == nil ? true : @options[:enable_screen_recording]).to_s, # true by default
        include_screen_recording_on_passing_script: (@options[:include_screen_recording_on_passing_script] || false).to_s # false by default
      }
    end

    def script_injection_rules
      return [] unless test_run.is_a?(TestRunWithTag)
      js_file_url = audit.run_on_tagsafe_tag_version? ? tag_version.js_file_url : tag.full_url
      [{ url: js_file_url, load_type: tag.load_type || 'async' }]
    end

    def allowed_request_urls
      domain.non_third_party_url_patterns.collect(&:pattern)
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