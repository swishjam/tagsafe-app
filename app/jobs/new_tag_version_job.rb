class NewTagVersionJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tag_version)
    return if tag_version.tag.release_monitoring_disabled?
    if tag_version.should_throttle_audit?
      tag_version.throttle_audit!
    else
      tag_version.tag.perform_audit_on_all_urls!(
        execution_reason: ExecutionReason.NEW_RELEASE, 
        tag_version: tag_version, 
        initiated_by_domain_user: nil, 
        options: {}
      )
    end
  end
end