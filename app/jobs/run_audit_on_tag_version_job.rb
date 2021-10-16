class RunAuditOnTagVersionJob < ApplicationJob
  def perform(audit:, tag_version:, url_to_audit_id:, execution_reason:, enable_tracing:, attempt_number:)
    AuditRunner.new(
      audit: audit,
      tag_version: tag_version,
      url_to_audit_id: url_to_audit_id,
      execution_reason: execution_reason,
      attempt_number: attempt_number,
      enable_tracing: enable_tracing
    ).run!
  end
end