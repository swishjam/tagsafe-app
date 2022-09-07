class PromoteTagsJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tags)
    TagManager::Promoter.promote_staged_changes(tags)
  end
end