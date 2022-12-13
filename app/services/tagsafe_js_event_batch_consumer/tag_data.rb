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

    private

    def missing_attr!(attr)
      raise InvalidTagDataError, "`tag_data` is missing required attr: `#{attr}`. Provided `tag_data`: #{@tag_data}"
    end
  end
end