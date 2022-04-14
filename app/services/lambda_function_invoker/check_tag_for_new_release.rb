module LambdaFunctionInvoker
  class CheckTagForNewRelease < Base
    self.lambda_function = 'check-tag-for-release'
    self.lambda_service = 'release-monitoring'
    self.results_consumer_klass = LambdaEventResponses::TagChecksResult
    self.results_consumer_job_queue = TagsafeQueue.CRITICAL
    self.has_no_executed_lambda_function = true

    def initialize(tag)
      @tag = tag
    end

    def request_payload
      {
        tag_id: @tag.id,
        current_minute_interval: @tag.tag_preferences.tag_check_minute_interval
      }
    end
  end
end