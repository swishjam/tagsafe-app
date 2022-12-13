module TagsafeJsEventBatchConsumer
  class InterceptedTags
    def initialize(container:,intercepted_tags_data:, tagsafe_js_event_batch:)
      @tagsafe_js_event_batch = tagsafe_js_event_batch
      @intercepted_tags_data = intercepted_tags_data
    end

    def consume!
    end
  end
end