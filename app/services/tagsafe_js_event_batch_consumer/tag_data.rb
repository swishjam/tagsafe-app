module TagsafeJsEventBatchConsumer
  class TagData
    class InvalidTagDataError < StandardError; end;

    def initialize(tag_data)
      @tag_data = tag_data
    end

    def url
      @tag_data['tag_url'] || missing_attr!('tag_url')
    end

    def load_type
      @tag_data['load_type'] || missing_attr!('load_type')
    end

    def intercepted_by_tagsafe_js?
      @tag_data['intercepted_by_tagsafe_js'] == nil ? missing_attr!('intercepted_by_tagsafe_js') : @tag_data['intercepted_by_tagsafe_js']
    end

    def optimized_by_tagsafe_js?
      @tag_data['optimized_by_tagsafe_js'] == nil ? missing_attr!('optimized_by_tagsafe_js') : @tag_data['optimized_by_tagsafe_js']
    end

    private

    def missing_attr!(attr)
      raise InvalidTagDataError, "`tag_data` is missing required attr: `#{attr}`. Provided `tag_data`: #{@tag_data}"
    end
  end
end