module TagsafeJsEventsConsumers
  class Base
    class InvalidDataError < StandardError; end;

    attr_accessor :data
    
    def initialize(data)
      @data = data
    end

    def event_type
      @data['event_type'] || missing_attr!("event_type")
    end

    def cloudflare_message_id
      @data['cloudflare_message_id'] || missing_attr!("cloudflare_message_id")
    end

    def domain_uid
      @data['domain_uid'] || missing_attr!("domain_uid")
    end

    def domain
      Domain.find_by!(uid: domain_uid)
    end

    def consume!
      raise "Subclass (#{self.class.to_s}) must implement `consume!` method."
    end

    private

    def missing_attr!(attr)
      raise InvalidDataError, "Missing require attribute: `#{attr}`. Provided `data`: #{@data}"
    end
  end
end