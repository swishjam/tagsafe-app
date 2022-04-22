module StepFunctionResponses
  class PerformanceAuditResult
    class LongTask
      def initialize(task_data)
        @task_data = task_data
        # {
        #   "duration": 532.975,
        #   "selfTime": 532.975,
        #   "startTime": 585.691,
        #   "endTime": 1118.666,
        #   "event": {
        #       "args": {},
        #       "cat": "v8",
        #       "dur": 532975,
        #       "name": "V8.Execute",
        #       "ph": "X",
        #       "pid": 13921,
        #       "tdur": 506331,
        #       "tid": 259,
        #       "ts": 15101499883,
        #       "tts": 197771
        #   },
        #   "group": {
        #       "id": "scriptEvaluation",
        #       "label": "Script Evaluation",
        #       "traceEventNames": [
        #           "EventDispatch",
        #           "EvaluateScript",
        #           "v8.evaluateModule",
        #           "FunctionCall",
        #           "TimerFire",
        #           "FireIdleCallback",
        #           "FireAnimationFrame",
        #           "RunMicrotasks",
        #           "V8.Execute"
        #       ]
        #   }
        # }
      end

      def task_type
        group['label']
      end

      def duration
        @task_data['duration']
      end

      def self_time
        @task_data['selfTime']
      end

      def start_time
        @task_data['startTime']
      end

      def end_time
        @task_data['endTime']
      end

      def event
        @task_data['event']
      end

      def group
        @task_data['group']
      end
    end
  end
end