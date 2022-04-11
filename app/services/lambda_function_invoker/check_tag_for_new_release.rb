module LambdaFunctionInvoker
  class CheckTagForNewRelease < Base
    lambda_function 'check-tag-for-release'
    lambda_service 'release-monitoring'
    consumer_klass LambdaEventResponses::TagChecksResult
    receiver_job_queue TagsafeQueue.CRITICAL
    has_no_executed_lambda_function

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