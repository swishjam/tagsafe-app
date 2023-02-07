module TagsafeJsDataConsumer
  class Resources
    def initialize(payload_parser)
      @payload_parser = payload_parser
      @resources = payload_parser.third_party_tags
      @container = payload_parser.container
    end

    def consume!
      @resources.each do |resource|
        existing_tag = @contain.tags.find_by(full_url: resource['tag_url'])
        if existing_tag
          # existing_tag.update!(
          #   load_type: resource['load_type'],
          # )
        else
          @container.tags.create!(
            page_load: @payload_parser.page_load,
            page_load_found_on: @payload_parser.page_load,
            full_url: resource.url,
            load_type: resource.load_type,
          )
        end
      end
    end
  end
end