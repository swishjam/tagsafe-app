module StepFunctionResponses
  class UrlCrawlResult < Base
    def process_results!
      if error
        url_crawl.errored!(error)
      elsif tag_urls.none?
        url_crawl.errored!("Unable to find any third party tags, Tagsafe crawler may be getting blocked by site.")
      else
        url_crawl.update!(num_first_party_bytes: num_first_party_bytes, num_third_party_bytes: num_third_party_bytes)
        TagManager::EvaluateUrlCrawlFoundTags.new(url_crawl: url_crawl, tag_urls: tag_urls).evaluate!
      end
    end

    def url_crawl
      @url_crawl ||= UrlCrawl.find(request_payload['url_crawl_id'])
    end
    alias record url_crawl

    def num_first_party_bytes
      @num_first_party_bytes ||= response_payload['first_party_bytes']
    end

    def num_third_party_bytes
      @num_third_party_bytes ||= response_payload['third_party_bytes']
    end

    def tag_urls
      @tag_urls ||= response_payload['tag_urls']
    end

    def error
      @error ||= step_function_error_message || response_payload['error'] || response_payload['error_message'] || response_payload['errorMessage']
    end
  end
end