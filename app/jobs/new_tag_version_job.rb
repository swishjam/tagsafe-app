class NewTagVersionJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tag_version)
    tag_version.tag.perform_audit_on_all_urls!(
      execution_reason: tag_version.first_version? ? ExecutionReason.RELEASE_MONITORING_ACTIVATED : ExecutionReason.NEW_RELEASE, 
      tag_version: tag_version, 
      initiated_by_container_user: nil,
    )
  end
end