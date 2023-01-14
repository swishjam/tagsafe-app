class NewTagJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL
  
  def perform(tag)
    TagManager::MarkTagAsTagsafeHostedIfPossible.new(self).determine!
    TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version! if is_tagsafe_hostable
    tag.perform_audit_on_all_should_audit_urls!(execution_reason: ExecutionReason.NEW_RELEASE, tag_version: nil, initiated_by_container_user: nil) if !is_tagsafe_hostable
    tag.send(:enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!)
    tag.tag_snippet.update_tag_snippet_details_view
  end
end