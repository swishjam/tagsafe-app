module TagManager
  class MarkTagAsTagsafeHostedIfPossible
    CHROME_USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0'
    SAFARI_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15'
    SAMSUNG_GALAXY_S22 = 'Mozilla/5.0 (Linux; Android 12; SM-S906N Build/QP1A.190711.020; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/80.0.3987.119 Mobile Safari/537.36'

    def initialize(tag)
      @tag = tag
    end

    def determine!
      if is_in_unhostable_tag_list? || !tag_has_static_content?
        @tag.update!(is_tagsafe_hostable: false, is_tagsafe_hosted: false, release_monitoring_interval_in_minutes: 0)
      else
        if @tag.container.can_host_with_tagsafe?
          @tag.update!(is_tagsafe_hostable: true, is_tagsafe_hosted: true)
        else
          @tag.update!(is_tagsafe_hostable: true, is_tagsafe_hosted: false)
        end
      end
    end

    private

    def is_in_unhostable_tag_list?
      %w[
        cdn-collin-dev.tagsafe.io
        cdn.tagsafe.io
      ].include?(@tag.url_hostname)
    end

    def tag_has_static_content?(attempts: 0)
      unique_hashes = [
        fetch_tags_hashed_content(CHROME_USER_AGENT),
        fetch_tags_hashed_content(SAFARI_USER_AGENT),
        fetch_tags_hashed_content(SAMSUNG_GALAXY_S22),
        fetch_tags_hashed_content(CHROME_USER_AGENT),
        fetch_tags_hashed_content(SAFARI_USER_AGENT),
      ].uniq!
      unique_hashes.count == 1
    rescue NoMethodError => e
      Sentry.capture_exception(e)
      if attempts < 3
        tag_has_static_content?(attempts: attempts + 1)
      else
        begin
          raise NoMethodError, "Cannot detect if #{@tag.uid} has static content after trying 3 times. Assuming it is not static."
        rescue NoMethodError => e
          Sentry.capture_exception(e)
          return false
        end
      end
    end

    def fetch_tags_hashed_content(user_agent)
      resp = HTTParty.get(@tag.full_url, headers: { 'User-Agent': user_agent })
      raise  "Invalid Tag #{@tag.full_url}, endpoint returned a #{resp.code} response." unless resp.code < 300
      Digest::MD5.hexdigest(resp.to_s)
    end
  end
end