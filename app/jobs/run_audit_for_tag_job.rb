class RunAuditForTagJob < ApplicationJob
  def perform(tag, tag_version, execution_reason)
    tag.run_audit!(tag_version, execution_reason)
  end
end