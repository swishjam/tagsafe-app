module TagsafeJsEventsConsumers
  class NewTags < Base

    def consume!
      new_tags = 0
      batch = NewTagsIdentifiedBatch.create!(cloudflare_message_id: @data['cloudflare_message_id'], domain: domain)
      
      @data['intercepted_tags'].each{ |tag_data| update_existing_tag(tag_data) }
      @data['new_tags'].each{ |t| new_tags += 1 if capture_new_tag(t, batch) }

      return if new_tags.zero?
      TagsafeInstrumentationManager::InstrumentationWriter.new(domain).write_current_instrumentation_to_cdn
    end

    private

    def update_existing_tag(tag_data)
      existing_tag = domain.tags.find_by(full_url: tag_data['tag_url'])
      if existing_tag
        existing_tag.touch(:last_seen_at)
      else
        Rails.logger.warn "Received `intercepted_tags` data for a tag that does not exist on #{domain_uid}: #{tag_data['tag_url']}"
      end
    end

    def capture_new_tag(tag_data, batch)
      tag_url = tag_data['tag_url']
      page_url_found_on = tag_data['page_url_found_on']
      load_type = tag_data['load_type']

      existing_tag = domain.tags.find_by(full_url: tag_url)
      if existing_tag
        Rails.logger.warn "Received `intercepted_tags` data for a tag that does not exist on #{domain_uid}: #{tag_url}"
        return false
      else
        if should_add_tag_url_to_do_not_capture_list?(tag_url)
          parsed_url = URI.parse(tag_url)
          stripped_url = [parsed_url.host, parsed_url.path].join('')
          domain.tag_url_patterns_to_not_capture.create(url_pattern: stripped_url)
        else
          tag = domain.tags.create(full_url: tag_url, new_tags_identified_batch: batch, last_seen_at: DateTime.now)
          if tag.errors.any?
            raise "Unable to add #{tag_url} to #{domain_uid}'s tags: #{tag.errors.full_messages.join('. ')}"
          end
        end
        # we want to re-write instrumentation if it's a capturable tag or not to update the tagUrlsToIgnore
        true
      end
    end

    def should_add_tag_url_to_do_not_capture_list?(tag_url)
      parsed_url = URI.parse(tag_url)

      reached_max_tags_for_url = domain.tags.where(url_domain: parsed_url.host, url_path: parsed_url.path).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_URL'] || 20).to_i
      return true if reached_max_tags_for_url

      reached_max_tags_for_host = domain.tags.where(url_domain: parsed_url.host).count >= (ENV['MAX_NUM_TAGS_FOR_SAME_HOST'] || 40).to_i
      return true if reached_max_tags_for_host

      false
    end

  end
end