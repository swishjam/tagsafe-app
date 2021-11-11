class RunAuditOnTagVersionJob < ApplicationJob
  def perform(audit:, tag_version:, url_to_audit_id:, execution_reason:, enable_tracing:, include_page_load_resources:, inline_injected_script_tags:)
    AuditRunner.new(
      audit: audit,
      tag_version: tag_version,
      url_to_audit_id: url_to_audit_id,
      execution_reason: execution_reason,
      enable_tracing: enable_tracing,
      include_page_load_resources: include_page_load_resources,
      inline_injected_script_tags: inline_injected_script_tags
    ).run!
  end
end