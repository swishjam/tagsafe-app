module TagsafeEmail
  class FunctionalTestSuiteFailedAlert < Base
    self.sendgrid_template_id = :'d-c16d7f991e8d43a59523b7f0f335a7b5'
    self.from_email = :'alerts@tagsafe.io'

    def initialize(user:, alert_configuration:, initiating_record:, triggered_alert:)
      @to_email = user.email
      audit = initiating_record
      @template_variables = {
        domain_url: alert_configuration.domain.url_hostname,
        tag_name: triggered_alert.tag.try_friendly_name,
        num_passed_tests: audit.num_passed_functional_tests,
        num_total_tests: audit.num_functional_tests_to_run - audit.test_runs_with_tag.not_retries.inconclusive.count,
        failing_functional_test_titles: audit.test_runs_with_tag.not_retries.conclusive.failed.collect{ |test_run| test_run.functional_test.title },
        audit_functional_tests_url: mail_safe_url("/tags/#{triggered_alert.tag.uid}/audits/#{audit.uid}/test_runs")
      }
    end
  end
end