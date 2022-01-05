module LambdaModerator
  class FunctionalTestRunner < Base
    lambda_service 'functional-test-runner'
    lambda_function 'run-test'

    attr_accessor :test_run

    def initialize(test_run, options = {})
      @test_run = test_run
      @options = options
      @executed_lambda_function_parent = test_run
    end

    def before_send
      test_run.update!(enqueued_at: Time.now)
    end

    def after_send
      test_run.update!(completed_at: Time.now)
    end

    def request_payload
      { 
        puppeteer_script: test_run.puppeteer_script_ran,
        expected_results: test_run.expected_results,
        first_party_url: domain.url,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: allowed_request_urls,
        max_script_exeuction_ms: @options[:max_script_exeuction_ms] || Flag.flag_value_for_objects(functional_test, domain, domain.organization, slug: 'max_functional_test_script_execution_ms').to_i,
        enable_screen_recording: (@options[:enable_screen_recording] == nil ? true : @options[:enable_screen_recording]).to_s, # true by default
        include_screen_recording_on_passing_script: (@options[:include_screen_recording_on_passing_script] || false).to_s # false by default
      }
    end

    def script_injection_rules
      case test_run.class.to_s
      when 'DryTestRun'
        []
      when 'TestRunWithoutTag'
        []
      when 'TestRunWithTag'
        [{ url:  tag_version.hosted_tagsafe_instrumented_js_file_url, load_type: 'async' }]
      end
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

    def required_payload_arguments
      %i[puppeteer_script third_party_tag_urls_and_rules_to_inject third_party_tag_url_patterns_to_allow first_party_url]
    end
  end
end