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
      @third_party_tags_data.each do |tag_data| 
        existing_tag = @container.tags.find_by(full_url: tag_data.url)
        if existing_tag
          update_existing_tag(existing_tag, tag_data)
        else
          create_new_tag_if_necessary(tag_data)
        end
      end
    end

    private

    def update_existing_tag(tag, tag_data)
      tag.tagsafe_js_intercepted_count += 1 if tag_data.intercepted_by_tagsafe_js?
      tag.tagsafe_js_not_intercepted_count += 1 if !tag_data.intercepted_by_tagsafe_js?
      tag.tagsafe_js_optimized_count += 1 if tag_data.optimized_by_tagsafe_js?
      tag.last_seen_at = Time.current
      tag.load_type = tag_data.load_type
      tag.save!

      existing_page_url_tag_found_on = tag.page_urls_tag_found_on.find_by(page_url: @tagsafe_js_event_batch.page_url)
      if existing_page_url_tag_found_on
        existing_page_url_tag_found_on.touch(:last_seen_at)
      else
        tag.page_urls << @tagsafe_js_event_batch.page_url
      end
    end

    def create_new_tag_if_necessary(tag_data)
      # should we just ignore optimzed Tags? Don't we want to count these in some fashion?
      return if tag_data.optimized_by_tagsafe_js?
      if should_no_longer_capture_provided_tag?(tag_data.url)
        parsed_url = URI.parse(tag_data.url)
        stripped_url = [parsed_url.host, parsed_url.path].join('')
        @container.tag_url_patterns_to_not_capture.create(url_pattern: stripped_url)
        @num_updates += 1
        false
      else
        tag = @container.tags.create(
          full_url: tag_data.url, 
          tagsafe_js_event_batch: @tagsafe_js_event_batch, 
          load_type: tag_data.load_type,
          tagsafe_js_intercepted_count: tag_data.intercepted_by_tagsafe_js? ? 1 : 0,
          tagsafe_js_not_intercepted_count: tag_data.intercepted_by_tagsafe_js? ? 0 : 1,
          page_urls_tag_found_on_attributes: [{ page_url: @tagsafe_js_event_batch.page_url, should_audit: true }]
        )
        raise "Unable to add #{tag_data.url} to #{@container.uid}'s tags: #{tag.errors.full_messages.join('. ')}" if tag.errors.any?
        @num_updates += 1
        tag
      end
    rescue => e
      Rails.logger.error "Unable to create Tag for #{tag_data.url}: #{e.inspect}"
      Resque.logger.error "Unable to create Tag for #{tag_data.url}: #{e.inspect}"
      false
    end

    def should_no_longer_capture_provided_tag?(tag_url)
      parsed_url = URI.parse(tag_url)

      reached_max_tags_for_url = @container.tags.where(url_hostname: parsed_url.host, url_path: parsed_url.path).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_URL'] || 20).to_i
      return true if reached_max_tags_for_url

      reached_max_tags_for_host = @container.tags.where(url_hostname: parsed_url.host).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_HOST'] || 40).to_i
      return true if reached_max_tags_for_host
      
      false
    end
  end
end