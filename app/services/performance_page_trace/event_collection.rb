module PerformancePageTrace
  class EventCollection
    include Enumerable

    def initialize(array_of_events_or_event_hashes)
      @events_array = parse_array_of_events_or_event_hashes_into_array_of_events(array_of_events_or_event_hashes)
    end

    def each(&block)
      @events_array.each(&block)
    end

    def where(name: nil, category: nil, resource_url: nil, &event_match_clause)
      if name.present?
        get_events_by_name(name)
      elsif category.present?
        get_events_by_category(category)
      elsif resource_url.present?
        get_events_related_to_url(resource_url)
      elsif block_given?
        event_collection_where(&event_match_clause)
      end
    end

    private

    def get_events_by_name(event_name)
      where{ |event| event.name == event_name }
    end

    def get_events_related_to_url(url)
      where{ |event| event.callframe_url == url || event.args.dig('data', 'url') == url }
    end

    def get_events_by_category(category)
      where{ |event| event.categories.includes?(category) }
    end

    def get_events_by_event_type(event_type)
      PerformancePageTrace::EventTypes.DICTIONARY[event_type].map do |event_type_phase_code|
        where{ |event| event.phase_code == event_type_phase_code }
      end.flatten!
    end

    def event_collection_where(&event_match_clause)
      return_array_of_events_as_event_collection do
        @events_array.select(&event_match_clause)
      end
    end

    def return_array_of_events_as_event_collection(&block)
      EventCollection.new(yield)
    end

    def parse_array_of_events_or_event_hashes_into_array_of_events(array_of_events_or_event_hashes)
      array_of_events_or_event_hashes.map do |event_or_event_hash| 
        if event_or_event_hash.is_a?(PerformancePageTrace::Event)
          event_or_event_hash
        else
          PerformancePageTrace::Event.new(event_or_event_hash)
        end
      end
    end
  end
end