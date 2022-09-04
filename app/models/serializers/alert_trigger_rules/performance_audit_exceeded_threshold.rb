module Serializers
  module AlertTriggerRules
    class PerformanceAuditExceededThreshold < Base
      attr_accessor :exceeded_metric, :operator, :exceeded_metric_value
      ACCEPTABLE_OPERATORS = %w[less_than greater_than]
      ACCEPTABLE_EXCEEDED_METRICS = %w[
        bytes
        dom_complete_delta
        dom_content_loaded_delta
        dom_interactive_delta
        entire_main_thread_execution_ms_delta
        entire_main_thread_blocking_executions_ms_delta
        first_contentful_paint_delta
        layout_duration_delta
        main_thread_blocking_execution_tag_responsible_for_delta
        main_thread_execution_tag_responsible_for_delta
        ms_until_first_visual_change_delta
        perceptual_speed_index_delta
        script_duration_delta
        speed_index_delta
        task_duration_delta
        tagsafe_score
      ]

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

      def valid?
        invalid_error_message.nil?
      end

      def invalid?
        invalid_error_message.present?
      end

      def invalid_error_message
        if !ACCEPTABLE_EXCEEDED_METRICS.include?(exceeded_metric)
          "Trigger rules's exceeded metric '#{exceeded_metric}' is invalid. Acceptable values are #{ACCEPTABLE_EXCEEDED_METRICS.join(', ')}."
        elsif !Util.string_is_numeric?(exceeded_metric_value)
          "Trigger rule's exceeded metric value #{exceeded_metric_value} is not a valid number."
        elsif !ACCEPTABLE_OPERATORS.include?(operator)
          "Trigger rule operator '#{operator}' is invalid. Acceptable values are: #{ACCEPTABLE_OPERATORS.join(', ')}."
        end
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