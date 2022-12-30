module TagsafeJsDataConsumer
  class PayloadParser
    class InvalidPayloadError < StandardError; end;

    def initialize(tagsafe_js_api_payload)
      @payload = tagsafe_js_api_payload
      create_page_load
    end

    def create_page_load
      @page_load ||= begin
        page_load = container.page_loads.find_or_create_by!(page_load_identifier: page_load_identifier) do |page_load|
          page_load.container = container
          page_load.page_url = find_or_create_page_url
          page_load.cloudflare_message_id = cloudflare_message_id
          page_load.num_tags_optimized_by_tagsafe_js = 0
          page_load.num_tags_not_optimized_by_tagsafe_js = 0
          # TODO: these timestamps don't make as much sense if we receive multiple events per page load
          page_load.page_load_ts = page_load_ts
          page_load.enqueued_at = enqueued_at_ts
        end
        page_load.num_tags_optimized_by_tagsafe_js += third_party_tags.count(&:optimized_by_tagsafe_js?)
        page_load.num_tags_not_optimized_by_tagsafe_js += (third_party_tags.count - page_load.num_tags_optimized_by_tagsafe_js)
        page_load.save!
        page_load
      end
    end
    alias page_load create_page_load

    def page_url
      @page_url ||= container.page_urls.find_or_create_by!(full_url: raw_page_url)
    end
    alias find_or_create_page_url page_url

    def container
      @container ||= Container.find_by!(uid: container_uid)
    rescue ActiveRecord::RecordNotFound => e
      raise InvalidPayloadError, "Could not find Container for provided `container_uid`: #{container_uid}"
    end

    def cloudflare_message_id
      @payload['cloudflare_message_id'] || missing_attr!("cloudflare_message_id")
    end

    def container_uid
      @payload['container_uid'] || missing_attr!("container_uid")
    end

    def page_load_identifier
      @payload['page_load_identifier'] || missing_attr!('page_load_identifier')
    end

    def page_load_ts
      @payload['page_load_ts'] ? DateTime.parse(@payload['page_load_ts']) : missing_attr!('page_load_ts')
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

    def performance_metrics
      @payload['performance_metrics'] || missing_attr!('performance_metrics')
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