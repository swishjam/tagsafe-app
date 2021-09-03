class GeppettoModerator::Senders::RunPerformanceAudit < GeppettoModerator::Senders::Base
  def initialize(audit:, audit_url:, auditing_tag_url:, num_test_iterations:, third_party_tag_url_patterns_to_allow:, third_party_tags_to_overwrite:, num_attempts:, disable_third_party_tags:)
    @endpoint = '/api/run_performance_audit' 
    @audit = audit
    @audit_url = audit_url
    @auditing_tag_url = auditing_tag_url
    @num_test_iterations = num_test_iterations
    @third_party_tag_url_patterns_to_allow = third_party_tag_url_patterns_to_allow
    @third_party_tags_to_overwrite = third_party_tags_to_overwrite
    @num_attempts = num_attempts
    @disable_third_party_tags = disable_third_party_tags
  end

  private

  def request_body
    {
      audit_id: @audit.id,
      audit_url: @audit_url,
      auditing_tag_url: @auditing_tag_url,
      num_test_iterations: @num_test_iterations,
      third_party_tag_url_patterns_to_allow: @third_party_tag_url_patterns_to_allow,
      third_party_tags_to_overwrite: @third_party_tags_to_overwrite,
      num_attempts: @num_attempts,
      disable_third_party_tags: @disable_third_party_tags
    }
  end
end