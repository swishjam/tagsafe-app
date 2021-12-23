module LambdaModerator
  class FunctionalTestRunner < Base
    lambda_service 'functional-test-runner'
    lambda_function 'run-test'

    def initialize(functional_test:, test_run_klass:, audit:, already_created_test_run: nil, domain: nil)
      @functional_test = functional_test
      @test_run = already_created_test_run
      @test_run_klass = test_run_klass
      @domain = domain
      @audit = audit
      @tag_version = audit&.tag_version
      @executed_lambda_function_parent = test_run
    end

    def test_run
      @test_run ||= @test_run_klass.create!(
        functional_test: @functional_test, 
        audit: @audit, 
        puppeteer_script_ran: @functional_test.puppeteer_script, 
        expected_results: @functional_test.expected_results
      )
    end

    def before_send
      test_run.update!(enqueued_at: Time.now)
    end

    def after_send
      test_run.update!(completed_at: Time.now)
    end

    def request_payload
      { 
        puppeteer_script: @functional_test.puppeteer_script,
        expected_results: @functional_test.expected_results,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: allowed_request_urls,
        enable_screen_recording: 'true'
      }
    end

    def script_injection_rules
      case test_run.class.to_s
      when 'DryTestRun'
        []
      when 'TestRunWithoutTag'
        []
      when 'TestRunWithTag'
        [{ url:  @tag_version.hosted_tagsafe_instrumented_js_file_url, load_type: 'async' }]
      end
    end

    def allowed_request_urls
      domain.non_third_party_url_patterns.collect(&:pattern)
    end

    def domain
      @domain ||= @functional_test.domain
    end

    def required_payload_arguments
      %i[puppeteer_script third_party_tag_urls_and_rules_to_inject third_party_tag_url_patterns_to_allow]
    end
  end
end