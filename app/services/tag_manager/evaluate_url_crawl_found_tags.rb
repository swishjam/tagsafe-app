module TagManager
  class EvaluateUrlCrawlFoundTags
    def initialize(url_crawl:, tag_urls:)
      @url_crawl = url_crawl
      @domain = @url_crawl.domain
      @tag_urls_and_metadata = tag_urls
    end

    def evaluate!
      if @url_crawl.completed? # just in case?
        Rails.logger.warn "Already processed URL Crawl #{@url_crawl.id}, bypassing..."
      else
        @tag_urls_and_metadata.each do |tag_url, metadata| 
          @url_crawl.retrieved_urls.create!(url: tag_url)
          add_tag_to_domain_if_not_already_present(tag_url, metadata)
        end
        # update_tags_no_longer_present_as_removed_from_site!
        @url_crawl.completed!
      end
    end

    private

    def add_tag_to_domain_if_not_already_present(tag_url, metadata)
      existing_tag = @domain.tags.find_without_query_params(tag_url, include_removed_tags: true)
      if existing_tag
        existing_tag.update!(last_seen_in_url_crawl_at: Time.now, removed_from_site_at: nil, last_captured_byte_size: metadata['bytes'])
      else
        if @url_crawl.domain.should_capture_tag?(tag_url)
          @url_crawl.found_tag!(tag_url, byte_size: metadata['bytes'])
          # @url_crawl.found_tag!(tag_url, enabled: create_tags_as_enabled)
        end
      end
    end

    # def create_tags_as_enabled
    #   @url_crawl.domain.is_generating_third_party_impact_trial ? false : @url_crawl.domain.general_configuration.enable_monitoring_on_new_tags
    # end
  end
end