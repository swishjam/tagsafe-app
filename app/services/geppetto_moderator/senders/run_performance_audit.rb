class GeppettoModerator::Senders::RunPerformanceAudit < GeppettoModerator::Senders::Base
  def initialize(audit:, audit_url:, num_test_iterations:, third_party_tag_to_audit:, third_party_tags_to_allow:, third_party_tags_to_overwrite:)
    @endpoint = '/api/run_performance_audit' 
    @audit = audit
    @audit_url = audit_url
    @num_test_iterations = num_test_iterations
    @third_party_tag_to_audit = third_party_tag_to_audit
    @third_party_tags_to_allow = third_party_tags_to_allow
    @third_party_tags_to_overwrite = third_party_tags_to_overwrite
  end

  def request_body
    {
      audit_id: @audit.id,
      audit_url: @audit_url,
      num_test_iterations: @num_test_iterations,
      third_party_tag_to_audit: @third_party_tag_to_audit,
      third_party_tags_to_allow: @third_party_tags_to_allow,
      third_party_tags_to_overwrite: @third_party_tags_to_overwrite
    }
  end
end