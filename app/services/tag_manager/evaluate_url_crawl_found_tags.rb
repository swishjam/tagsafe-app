module TagManager
  class EvaluateUrlCrawlFoundTags
    def initialize(url_crawl:, tag_urls:, initial_crawl:)
      @url_crawl = url_crawl
      @domain = @url_crawl.domain
      @tag_urls_and_load_types = tag_urls
      @initial_crawl = initial_crawl
    end

    def evaluate!
      if @url_crawl.completed? # just in case?
        Rails.logger.warn "Already processed URL Crawl #{@url_crawl.id}, bypassing..."
      else
        @tag_urls_and_load_types.each{ |tag_url, load_type| add_tag_to_domain_if_necessary(tag_url, load_type) }
        update_tags_no_longer_present_as_removed_from_site!
        @url_crawl.completed!
      end
    end

    private

    def add_tag_to_domain_if_necessary(tag_url, load_type)
      if @domain.should_capture_tag?(tag_url)
        existing_full_url_tag = @domain.tags.still_on_site.find_by(full_url: tag_url)
        if existing_full_url_tag.nil?
          evaluate_new_full_url(tag_url, load_type)
        else
          remove_full_url_from_starting_tags(tag_url)
        end
      end
    end

    def evaluate_new_full_url(tag_url, load_type)
      if existing_tag_without_query_params = @domain.tags.find_without_query_params(tag_url)
        # already has this tag but the query params have changed
        TagUrlQueryParamsChangedEvent.create!(triggerer: existing_tag_without_query_params, metadata: {
          removed_url_query_params: existing_tag_without_query_params.url_query_param, 
          added_url_query_params: URI.parse(tag_url).query
        })
        remove_url_from_starting_tags_without_query_params(tag_url)
      elsif previously_removed_tag = @domain.tags.find_removed_tag(tag_url)
        # the tag was removed previously, but has since been re-added
        TagAddedToSiteEvent.create!(triggerer: previously_removed_tag)
      elsif previously_removed_tag_without_query_params = @domain.tags.find_removed_tag_without_query_params(tag_url)
        # the tag was removed previously, but has since been re-added with new query parameters
        TagAddedToSiteEvent.create!(triggerer: previously_removed_tag_without_query_params)
        TagUrlQueryParamsChangedEvent.create!(triggerer: previously_removed_tag_without_query_params, metadata: {
          removed_url_query_params: previously_removed_tag_without_query_params.url_query_param, 
          added_url_query_params: URI.parse(tag_url).query
        })
      else
        # new tag
        @url_crawl.found_tag!(tag_url, load_type: load_type, initial_crawl: @initial_crawl)
      end
    end

    def update_tags_no_longer_present_as_removed_from_site!
      return if ENV['REMOVED_TAGS_IN_URL_CRAWLS'] == 'false'
      tag_urls_that_were_previously_active_on_this_page_url.each do |tag_url|
        tag = @domain.tags.find_by(full_url: tag_url)
        TagRemovedFromSiteEvent.create!(triggerer: tag)
      end
    end

    def remove_full_url_from_starting_tags(tag_url)
      tag_urls_that_were_previously_active_on_this_page_url.delete(tag_url)
    end

    def remove_url_from_starting_tags_without_query_params(tag_url)
      parsed_new_tag_url = URI.parse(tag_url)
      tag_urls_that_were_previously_active_on_this_page_url.each do |existing_tag_url|
        parsed_existing_tag_url = URI.parse(existing_tag_url)
        # find the tag URL from there previous query params and remove it from the already subscribed list
        if parsed_existing_tag_url.host == parsed_new_tag_url.host && parsed_existing_tag_url.path == parsed_new_tag_url.path
          remove_full_url_from_starting_tags(existing_tag_url)
        end
      end
    end

    def tag_urls_that_were_previously_active_on_this_page_url
      @tag_urls_that_were_previously_active_on_this_page_url ||= @url_crawl.page_url.tags_found_on_url.still_on_site.collect(&:full_url) 
    end
  end
end