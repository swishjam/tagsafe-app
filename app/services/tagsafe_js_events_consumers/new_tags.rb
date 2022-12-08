module TagsafeJsEventsConsumers
  class NewTags < Base

    def consume!
      new_tags = 0
      @data['new_tags'].each{ |t| new_tags += 1 if capture_tag_data(t) }
      return if new_tags.zero?
      TagsafeInstrumentationManager::InstrumentationWriter.new(domain).write_current_instrumentation_to_cdn
    end

    def capture_tag_data(tag_data)
      new_tag_url = tag_data['tag_url']
      page_url_found_on = tag_data['page_url_found_on']
      load_type = tag_data['load_type']

      if domain.tags.find_by(full_url: new_tag_url)
        Rails.logger.warn "Received NewTags TagsafeJS event for a pre-existing tag. #{domain_uid}'s instrumentation may be out of sync."
        return false
      else
        tag = domain.tags.create(full_url: new_tag_url)
        if tag.errors.any?
          Rails.logger.error "Unable to add #{new_tag_url} to #{domain_uid}'s tags: #{tag.errors.full_messages.join('. ')}"
          return false
        end
        true
      end
    end

  end
end