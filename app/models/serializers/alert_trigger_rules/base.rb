module Serializers
  module AlertTriggerRules
    class Base
      def self.load(stringified_trigger_rules_json)
        initialize_from_json(JSON.parse(stringified_trigger_rules_json || '{}'))
      end

      def self.dump(trigger_rules)
        return trigger_rules if trigger_rules.is_a?(String)
        trigger_rules.to_json
      end

      def valid?
        raise "Subclass #{self.class} must implement `valid?` instance_method."
      end

      def invalid?
        raise "Subclass #{self.class} must implement `invalid?` instance_method."
      end

      def invalid_error_message
        raise "Subclass #{self.class} must implement `invalid_error_message` instance_method."
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