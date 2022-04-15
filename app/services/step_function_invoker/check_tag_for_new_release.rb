module StepFunctionInvoker
  class CheckTagForNewRelease < Base
    self.results_consumer_klass = StepFunctionResponses::TagChecksResult
    self.results_consumer_job_queue = TagsafeQueue.CRITICAL
    self.has_no_executed_step_function = true

    def initialize(tag)
      @tag = tag
    end

    def unique_identifer
      "#{@tag.uid}-#{DateTime.now.to_s}"
    end

    def request_payload
      {
        tag_id: @tag.id,
        current_minute_interval: @tag.tag_preferences.tag_check_minute_interval
      }
    end
  end
end