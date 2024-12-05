module TagsafeJsDataConsumer
  class Resources
    def initialize(payload_parser)
      @payload_parser = payload_parser
      @resources = payload_parser.third_party_tags
      @container = payload_parser.container
      @num_tags_created = 0
    end

    def consume!
      @resources.each do |resource|
        existing_tag = @container.tags.find_by(full_url: resource.url)
        if existing_tag
          # existing_tag.update!(
          #   load_type: resource['load_type'],
          # )
        elsif @container.tag_url_patterns_to_not_capture.none?{ |pattern| resource.url.match?(pattern.url_pattern) }
          begin
            tag = @container.tags.create!(
              page_load_found_on: @payload_parser.page_load,
              full_url: resource.url,
              load_type: resource.load_type,
            )
            TagManager::MarkTagAsTagsafeHostedIfPossible.new(tag).determine!
            TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version! if tag.is_tagsafe_hostable
            tag.send(:enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!)
            @num_tags_created += 1
          rescue => e
            Sentry.capture_exception(e)
            Rails.logger.error "Unable to add tag #{resource.url} to container #{container.uid}: #{e.message}"
          end
        end
      end
      @num_tags_created
    end
  end
end