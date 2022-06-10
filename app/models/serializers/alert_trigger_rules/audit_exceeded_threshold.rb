module Serializers
  module AlertTriggerRules
    class AuditExceededThreshold < Base
      attr_accessor :exceeded_metric, :operator, :exceeded_metric_value

      def self.initialize_from_json(json)
        new(
          exceeded_metric: json['exceeded_metric'], 
          exceeded_metric_value: json['exceeded_metric_value'],
          operator: json['operator']
        )
      end

      def initialize(exceeded_metric:, exceeded_metric_value:, operator:)
        @exceeded_metric = exceeded_metric
        @operator = operator
        @exceeded_metric_value = exceeded_metric_value.to_f
      end

      def human_exceeded_metric(capitalize: false)
        if capitalize
          exceeded_metric.split('_').map(&:capitalize!).join(' ')
        else
          exceeded_metric.split('_').join(' ')
        end
      end
    
      def human_operator
        operator.split('_').join(' ')
      end
    
      def human_exceeded_metric_value
        exceeded_metric == 'tagsafe_score' ? exceeded_metric_value : "#{exceeded_metric_value} ms"
      end

      def to_h
        {
          exceeded_metric: exceeded_metric,
          exceeded_metric_value: exceeded_metric_value,
          operator: operator,
        }
      end

      def to_json
        to_h.to_json
      end
    end
  end
end