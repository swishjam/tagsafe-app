module TagManager
  class EvaluateUrlCrawlFoundTags
    def initialize(url_crawl:, tag_urls:)
      @url_crawl = url_crawl
      @domain = @url_crawl.domain
      @tag_urls_and_load_types = tag_urls
    end

    def evaluate!
      if @url_crawl.completed? # just in case?
        Rails.logger.warn "Already processed URL Crawl #{@url_crawl.id}, bypassing..."
      else
        @tag_urls_and_load_types.each do |tag_url, load_type| 
          @url_crawl.retrieved_urls.create!(url: tag_url)
          add_tag_to_domain_if_not_already_present(tag_url, load_type)
        end
        # update_tags_no_longer_present_as_removed_from_site!
        @url_crawl.completed!
      end
    end

    private

    def add_tag_to_domain_if_not_already_present(tag_url, _load_type)
      existing_tag = @domain.tags.find_without_query_params(tag_url, include_removed_tags: true)
      if existing_tag
        existing_tag.update!(last_seen_in_url_crawl_at: Time.now, removed_from_site_at: nil)
      else
        @url_crawl.found_tag!(tag_url)
      end
    end
  end
end