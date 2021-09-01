module TagManager
  class Evaluator
    attr_accessor :tag_version

    def initialize(tag)
      @tag = tag
      @tag_version = nil
      @tag_changed = false
    end

    def evaluate!
      @response = fetcher.fetch!
      capture_tag_check!
      if fetcher.success
        if @response.body.nil?
          Rails.logger.error "Fetch for #{@tag.full_url} (id: #{@tag.id}) resulted in an empty response. Skipping tag version creation and test runs."
        else
          @hashed_content = TagManager::Hasher.hash!(@response.body)
          try_tag_change!
        end
      else
        Rails.logger.error "Fetch for #{@tag.full_url} (id: #{@tag.id}) resulted in a #{@response.code} response code. Skipping tag version creation and test runs."
      end
    end

    # def update_tag_version!(tag_version)
    #   @response = fetcher.fetch!
    #   capture_tag_check!
    #   if fetcher.success
    #     if @response.body.nil?
    #       Rails.logger.error "Fetch for #{@tag.full_url} (id: #{@tag.id}) resulted in an empty response. Skipping tag version creation and test runs."
    #     else
    #       @hashed_content = TagManager::Hasher.hash!(@response.body)
    #       @tag_version = TagManager::ChangeProcessor.new(@tag, @response.body, hashed_content: @hashed_content).update_tag_version!(tag_version)
    #     end
    #   else
    #     Rails.logger.error "Fetch for #{@tag.full_url} (id: #{@tag.id}) resulted in a #{@response.code} response code. Skipping tag version creation and test runs."
    #   end
    # end

    def tag_changed?
      @tag_changed
    end

    private

    def fetcher
      @fetcher ||= TagManager::Fetcher.new(@tag.full_url)
    end

    def capture_tag_check!
      if @tag.tag_preferences.should_log_tag_checks
        TagCheck.create(
          response_time_ms: fetcher.response_time_ms, 
          response_code: fetcher.response_code, 
          tag: @tag
        )
      end
    end

    def try_tag_change!
      if should_capture_tag_change?
        Rails.logger.info "Capturing a change to tag #{@tag.full_url}."
        @tag_changed = true
        @tag_version = TagManager::ChangeProcessor.new(@tag, @response.body, hashed_content: @hashed_content).process_change!
      end
    end

    def should_capture_tag_change?
      @tag.has_no_versions? || tag_content_changed?
    end

    def tag_content_changed?
      @tag.most_recent_version.hashed_content != @hashed_content
    end
  end
end