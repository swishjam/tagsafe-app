module StepFunctionResponses
  class PerformanceAuditResult
    class PerformanceMetrics
      def initialize(performance_metrics_hash)
        @performance_metrics_hash = performance_metrics_hash
      end
  
      def dom_complete
        @dom_complete ||= @performance_metrics_hash['DOMComplete']
      end
  
      def dom_content_loaded
        @dom_content_loaded ||= @performance_metrics_hash['DOMContentLoaded']
      end
  
      def dom_interactive
        @dom_interactive ||= @performance_metrics_hash['DOMInteractive']
      end
  
      def first_contentful_paint
        @first_contentful_paint ||= @performance_metrics_hash['FirstContentfulPaint']
      end
  
      def layout_duration
        @layout_duration ||= @performance_metrics_hash['LayoutDuration']
      end
  
      def script_duration
        @script_duration ||= @performance_metrics_hash['ScriptDuration']
      end
  
      def task_duration
        @task_duration ||= @performance_metrics_hash['TaskDuration']
      end
    end
  end
end