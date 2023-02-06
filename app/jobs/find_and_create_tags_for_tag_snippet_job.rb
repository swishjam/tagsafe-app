class FindAndCreateTagsForTagSnippetJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tag_snippet, tag_snippet_content)
    transaction = Sentry.start_transaction(op: 'FindAndCreateTagsForTagSnippetJob.perform')
    
    raise "TagSnippet already has associated Tags, delete Tags first before calling `find_and_create_associated_tags_added_to_page_by_snippet`" if tag_snippet.tags.any?
    attach_tag_snippet_content(tag_snippet, tag_snippet_content)
    begin
      tag_datas = TagManager::FindTagsInTagSnippet.find!(tag_snippet.encoded_content)
      tag_datas.each{ |data| create_tag_from_found_tag_data(tag_snippet, data) }
    rescue => e
      Rails.logger.error "TagManager::FindTagsInTagSnippet.find! failed, unable to capture tag data: #{e.message}"
      Sentry.capture_exception(e)
    end
    tag_snippet.found_all_tags_injected_by_snippet!

    transaction.finish
  end

  private

  def attach_tag_snippet_content(tag_snippet, tag_snippet_content)
    Util.create_dir_if_neccessary(Rails.root, 'tmp', 'tag_snippets')

    filepath = Rails.root.join('tmp', 'tag_snippets', "#{tag_snippet.uid}-content.html")
    file = File.open(filepath, 'w')
    file.puts(tag_snippet_content.force_encoding('UTF-8'))
    file.close

    tag_snippet.content.attach(
      io: File.open(filepath), 
      filename: "#{tag_snippet.uid}-content.html", 
      content_type: 'text/html'
    )

    File.delete(filepath)
  end

  def create_tag_from_found_tag_data(tag_snippet, tag_data_obj)
    tag = tag_snippet.tags.create!(container: tag_snippet.container, full_url: tag_data_obj['url'], load_type: tag_data_obj['load_type'])
    # NewTagJob.perform_now(tag)
    TagManager::MarkTagAsTagsafeHostedIfPossible.new(tag).determine!
    TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version! if tag.is_tagsafe_hostable
    tag.send(:enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!)
  rescue => e
    Sentry.capture_exception(e)
    Rails.logger.error("Error creating Tag from found Tag data: #{e.message}")
    Rails.logger.error("Tag data: #{tag_data_obj}")
  end
end