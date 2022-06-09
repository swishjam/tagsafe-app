module Serializers
  module AlertTriggerRules
    class Base
      def self.load(stringified_trigger_rules_json)
        initialize_from_json(JSON.parse(stringified_trigger_rules_json || '{}'))
      end

      def self.dump(trigger_rules)
        # unless serialized_trigger_rules.is_a?(self)
        #   raise ::ActiveRecord::SerializationTypeMismatch,
        #     "Attribute was supposed to be a #{self}, but was a #{serialized_trigger_rules.class}. -- #{serialized_trigger_rules.inspect}"
        # end
        trigger_rules.to_json
      end

      def self.initialize_from_json(json_trigger_rules)
        raise "Subclass #{self.class} must implement `initialize_from_json` class method."
      end

      def to_json
        raise "Subclass #{self.class} must implement `.to_json` instance method."
      end
    end
  end
end