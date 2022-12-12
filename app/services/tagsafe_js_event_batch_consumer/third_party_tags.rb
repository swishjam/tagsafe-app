module TagsafeJsEventBatchConsumer
  class ThirdPartyTags
    attr_reader :num_updates

    def initialize(container:, third_party_tags_data:, tagsafe_js_event_batch:)
      @container = container
      @tagsafe_js_event_batch = tagsafe_js_event_batch
      @third_party_tags_data = third_party_tags_data
      @num_updates = 0
    end

    def consume!
      @third_party_tags_data.each{ |tag_data| create_or_update_tag_from_tag_data(tag_data) }
    end

    private

    def create_or_update_tag_from_tag_data(tag_data)
      existing_tag = @container.tags.find_by(full_url: tag_data.url)
      if existing_tag
        existing_tag.touch(:last_seen_at)
      else
        create_new_tag_if_necessary(tag_data)
        @num_updates += 1
      end
    end

    def create_new_tag_if_necessary(tag_data)
      if should_capture_tag?(tag_data.url)
        parsed_url = URI.parse(tag_data.url)
        stripped_url = [parsed_url.host, parsed_url.path].join('')
        @container.tag_url_patterns_to_not_capture.create(url_pattern: stripped_url)
      else
        tag = @container.tags.create(full_url: tag_data.url, tagsafe_js_event_batch: @tagsafe_js_event_batch, last_seen_at: Time.current)
        if tag.errors.any?
          raise "Unable to add #{tag_data.url} to #{@container.uid}'s tags: #{tag.errors.full_messages.join('. ')}"
        end
      end
    rescue => e
      Rails.logger.error "Unable to create Tag for #{tag_data.url}: #{e.inspect}"
      Resque.logger.error "Unable to create Tag for #{tag_data.url}: #{e.inspect}"
    end

    def should_capture_tag?(tag_url)
      parsed_url = URI.parse(tag_url)

      reached_max_tags_for_url = @container.tags.where(url_hostname: parsed_url.host, url_path: parsed_url.path).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_URL'] || 20).to_i
      return true if reached_max_tags_for_url

      reached_max_tags_for_host = @container.tags.where(url_hostname: parsed_url.host).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_HOST'] || 40).to_i
      return true if reached_max_tags_for_host
      
      false
    end
  end
end