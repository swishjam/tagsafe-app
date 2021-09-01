module TagManager
  class EvaluateDomainTags
    def initialize(domain:, tag_urls:, url_scanned:, initial_scan:, should_remove_tags: ENV['SHOULD_AUTO_REMOVE_TAGS'] == 'true')
      @domain = domain
      @tag_urls = tag_urls
      @url_scanned = url_scanned
      @initial_scan = initial_scan
      @pre_existing_tag_urls = @domain.tags.still_on_site.collect(&:full_url)
      @should_remove_tags = should_remove_tags
    end

    def evaluate!
      @tag_urls.each{ |tag_url| add_tag_to_domain_if_necessary(tag_url) }
      remove_tags_removed_from_site if @should_remove_tags
    end

    private

    def add_tag_to_domain_if_necessary(tag_url)
      if @domain.should_capture_tag?(tag_url)
        existing_full_url_tag = @domain.tags.still_on_site.find_by(full_url: tag_url)
        if existing_full_url_tag
          remove_full_url_from_starting_tags(tag_url)
        else
          evaluate_new_full_url(tag_url)
        end
      end
    end

    def evaluate_new_full_url(url)
      if existing_tag_without_query_params = @domain.tags.find_without_query_params(url)
        # already has this tag but the query params have changed
        # update the existing tag with new query params...?
        tag_query_parameter_changed!(existing_tag_without_query_params, url)
      elsif previously_removed_tag = @domain.tags.find_removed_tag(url)
        # the tag was removed previously, but has since been re-added
        previously_removed_tag.unremove_from_site!
      elsif previously_removed_tag_without_query_params = @domain.tags.find_removed_tag_without_query_params(url)
        # the tag was removed previously, but has since been re-added with new query parameters
        previously_removed_tag_without_query_params.unremove_from_site!
        tag_query_parameter_changed!(previously_removed_tag_without_query_params, url)
      else
        # new tag
        @domain.add_tag!(url, @url_scanned, initial_scan: @initial_scan)
      end
    end

    def tag_query_parameter_changed!(tag, url_with_new_query_param)
      parsed_new_url = URI.parse(url_with_new_query_param)
      tag.update(full_url: url_with_new_query_param, url_query_param: parsed_new_url.query)
      remove_url_from_starting_tags_without_query_params(url_with_new_query_param) if @should_remove_tags
    end

    def remove_tags_removed_from_site
      @pre_existing_tag_urls.each do |url|
        tag = @domain.tags.find_by(full_url: url)
        tag.remove_from_site!
      end
    end

    def remove_full_url_from_starting_tags(url)
      @pre_existing_tag_urls.delete(url)
    end

    def remove_url_from_starting_tags_without_query_params(url)
      parsed_new_url = URI.parse(url)
      @pre_existing_tag_urls.each do |existing_url|
        parsed_existing_url = URI.parse(existing_url)
        # find the tag URL from there previous query params and remove it from the already subscribed list
        if parsed_existing_url.host == parsed_new_url.host && parsed_existing_url.path == parsed_new_url.path
          remove_full_url_from_starting_tags(existing_url)
        end
      end
    end
  end
end