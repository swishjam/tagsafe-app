class GeppettoModerator::Senders::RunLighthouseAudit < GeppettoModerator::Senders::Base
  def initialize(audit:, url_to_audit:, num_test_iterations:, script_url:)
    @endpoint = '/api/run_lighthouse' 
    @audit = audit
    @url_to_audit = url_to_audit
    @num_test_iterations = num_test_iterations
    @script_url = script_url
  end

  def request_body
    {
      audit_id: @audit.id,
      lighthouse_audit_url: @url_to_audit,
      num_test_iterations: @num_test_iterations,
      script_url: @script_url
    }
  end
end