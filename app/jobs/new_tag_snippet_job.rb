class NewTagSnippetJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tag_snippet)
    raise "TagSnippet already has associated Tags, delete Tags first before calling `find_and_create_associated_tags_added_to_page_by_snippet`" if tag_snippet.tags.any?
    try_to_find_tags(tag_snippet)
  end

  private

  def try_to_find_tags(tag_snippet, attempts: 0)
    tag_datas = TagManager::FindTagsInTagSnippet.find!(tag_snippet.executable_javascript, tag_snippet.script_tags_attributes)
    tag_datas.each do |tag_data|
      tag = tag_snippet.tags.create!(container: tag_snippet.container, full_url: tag_data['url'], load_type: tag_data['load_type'])
      # NewTagJob.perform_now(tag)
      TagManager::MarkTagAsTagsafeHostedIfPossible.new(tag).determine!
      TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version! if tag.is_tagsafe_hostable
      tag.send(:enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!)
    end
    tag_snippet.found_all_tags_injected_by_snippet!
  rescue ActiveStorage::FileNotFoundError => e
    if attempts < 5
      # I know, this is gross
      sleep(attempts.seconds)
      try_to_find_tags(tag_snippet, attempts: attempts + 1)
    else
      raise ActiveStorage::FileNotFoundError, e.message
    end
  end
end