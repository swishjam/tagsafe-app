class NewTagJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL
  
  def perform(tag)
    TagManager::MarkTagAsTagsafeHostedIfPossible.new(tag).determine!
    TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version! if tag.is_tagsafe_hostable
    tag.send(:enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!)
  end
end