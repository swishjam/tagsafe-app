module PerformancePageTrace
  class Event
    def initialize(event_attributes)
      raise StandardError, "`PerformancePageTrace::Event initialized with invalid event_attributes of type #{event_attributes.class}, must be a Hash" unless event_attributes.is_a?(Hash)
      @event_attributes = event_attributes
    end

    def to_h
      @event_attributes
    end

    def <=>(comparable)
      ts <=> comparable.ts
    end

    def name
      @event_attributes['name']
    end

    def ts
      @event_attributes['ts']
    end

    def type
      @event_attributes['ph']
    end
    alias phase_code type

    def category_string
      @event_attributes['cat']
    end
    alias category category_string
    alias cat category_string

    def categories
      category_string.split(',')
    end

    def args
      @event_attributes['args']
    end
    alias arguments args

    def callframe_url
      args.dig('callFrame', 'url')
    end
  end
end