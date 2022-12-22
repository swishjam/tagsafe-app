module TagsafeJsEventBatchConsumer
  class PayloadParser
    class InvalidPayloadError < StandardError; end;

    def initialize(tagsafe_js_api_payload)
      @payload = tagsafe_js_api_payload
      create_tagsafe_js_event_batch
    end

    def create_tagsafe_js_event_batch
      @event_batch ||= TagsafeJsEventBatch.create!(
        container: container,
        page_url: find_or_create_page_url,
        cloudflare_message_id: cloudflare_message_id,
        tagsafe_js_ts: tagsafe_js_ts,
        enqueued_at: enqueued_at_ts
      )
    end
    alias tagsafe_js_event_batch create_tagsafe_js_event_batch

    def page_url
      @page_url ||= container.page_urls.find_or_create_by!(full_url: raw_page_url)
    end
    alias find_or_create_page_url page_url

    def container
      @container ||= Container.find_by!(uid: container_uid)
    end

    def cloudflare_message_id
      @payload['cloudflare_message_id'] || missing_attr!("cloudflare_message_id")
    end

    def container_uid
      @payload['container_uid'] || missing_attr!("container_uid")
    end

    def tagsafe_js_ts
      @payload['tagsafe_js_ts'] ? DateTime.parse(@payload['tagsafe_js_ts']) : missing_attr!('tagsafe_js_ts')
    end

    def enqueued_at_ts
      @payload['enqueued_at_ts'] ? DateTime.parse(@payload['enqueued_at_ts']) : missing_attr!('enqueued_at_ts')
    end

    def intercepted_tags
      @payload['intercepted_tags'] ? unique_tag_data(@payload['intercepted_tags']) : missing_attr!('intercepted_tags')
    end

    def third_party_tags
      @payload['third_party_tags'] ? unique_tag_data(@payload['third_party_tags']) : missing_attr!('third_party_tags')
    end

    def errors
      @payload['errors']
    end

    def warnings
      @payload['warnings']
    end

    private

    def raw_page_url
      @payload['full_page_url'] || missing_attr!('full_page_url')
    end

    def unique_tag_data(tag_data_arr)
      tag_data_arr.map{ |data| TagData.new(data) }.uniq{ |tag_data| tag_data.url }
    end

    def missing_attr!(arg)
      raise InvalidPayloadError, "TagsafeJS API payload is missing required argument: `#{arg}`. Provided payload: #{@payload}"
    end
  end
end