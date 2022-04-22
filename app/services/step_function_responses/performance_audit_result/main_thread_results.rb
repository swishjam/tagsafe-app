module StepFunctionResponses
  class PerformanceAuditResult
    class MainThreadResults
      def initialize(main_thread_results_hash)
        @main_thread_results_hash = main_thread_results_hash
      end

      def total_execution_ms_for_tag
        @main_thread_results_hash['total_execution_ms_for_tag'] || 0
      end

      def tags_long_tasks
        (@main_thread_results_hash['tags_long_tasks'] || []).map{ |task| LongTask.new(task) }
      end
    end
  end
end