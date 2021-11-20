class RunAuditOnTagVersionJob < ApplicationJob
  def perform(audit:, tag_version:, url_to_audit_id:, execution_reason:, options: {})
    AuditRunner.new(
      audit: audit,
      tag_version: tag_version,
      url_to_audit_id: url_to_audit_id,
      execution_reason: execution_reason,
      options: options
    ).run!
  end
end