module TagManager
  class EvaluateUrlCrawlFoundTags
    def initialize(url_crawl:, tag_urls:, initial_crawl:)
      @url_crawl = url_crawl
      @domain = @url_crawl.domain
      @tag_urls = tag_urls
      @initial_crawl = initial_crawl
      # @pre_existing_tag_urls_for_this_page = @domain.tags.still_on_site.present_on_page_url(@url_crawl.url).collect(&:full_url)
      # TODO: need to scope this to the url being crawled...
      @pre_existing_tag_urls_for_this_page = @domain.tags.still_on_site.collect(&:full_url)
    end

    def evaluate!
      if already_processed?
        Rails.logger.warn "Already processed URL Crawl #{@url_crawl.id}, bypassing..."
      else
        @tag_urls.each{ |tag_url| add_tag_to_domain_if_necessary(tag_url) }
        remove_tags_removed_from_site
        @url_crawl.completed!
      end
    end

    private

    def already_processed?
      @url_crawl.completed?
    end

    def add_tag_to_domain_if_necessary(tag_url)
      if @domain.should_capture_tag?(tag_url)
        existing_full_url_tag = @domain.tags.still_on_site.find_by(full_url: tag_url)
        if existing_full_url_tag.nil?
          evaluate_new_full_url(tag_url)
        else
          remove_full_url_from_starting_tags(tag_url)
        end
      end
    end

    def evaluate_new_full_url(tag_url)
      if existing_tag_without_query_params = @domain.tags.find_without_query_params(tag_url)
        # already has this tag but the query params have changed
        tag_query_parameter_changed!(existing_tag_without_query_params, tag_url)

      elsif previously_removed_tag = @domain.tags.find_removed_tag(tag_url)
        # the tag was removed previously, but has since been re-added
        @url_crawl.unremove_tag_from_site!(previously_removed_tag)

      elsif previously_removed_tag_without_query_params = @domain.tags.find_removed_tag_without_query_params(tag_url)
        # the tag was removed previously, but has since been re-added with new query parameters
        @url_crawl.unremove_tag_from_site!(previously_removed_tag_without_query_params)
        @url_crawl.query_params_changed_for_tag(previously_removed_tag_without_query_params, tag_url)

      else
        # new tag
        @url_crawl.found_tag!(tag_url, initial_crawl: @initial_crawl)
      end
    end

    def tag_query_parameter_changed!(tag, url_with_new_query_param)
      @url_crawl.query_params_changed_for_tag!(tag, url_with_new_query_param)
      remove_url_from_starting_tags_without_query_params(url_with_new_query_param)
    end

    def remove_tags_removed_from_site
      @pre_existing_tag_urls_for_this_page.each do |tag_url|
        tag = @domain.tags.find_by(full_url: tag_url)
        @url_crawl.tag_removed_from_site!(tag)
      end
    end

    def remove_full_url_from_starting_tags(tag_url)
      @pre_existing_tag_urls_for_this_page.delete(tag_url)
    end

    def remove_url_from_starting_tags_without_query_params(tag_url)
      parsed_new_tag_url = URI.parse(tag_url)
      @pre_existing_tag_urls_for_this_page.each do |existing_tag_url|
        parsed_existing_tag_url = URI.parse(existing_tag_url)
        # find the tag URL from there previous query params and remove it from the already subscribed list
        if parsed_existing_tag_url.host == parsed_new_tag_url.host && parsed_existing_tag_url.path == parsed_new_tag_url.path
          remove_full_url_from_starting_tags(existing_url)
        end
      end
    end
  end
end