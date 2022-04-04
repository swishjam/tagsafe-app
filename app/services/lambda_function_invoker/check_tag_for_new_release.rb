module LambdaFunctionInvoker
  class CheckTagForNewRelease < Base
    lambda_function 'check-tag-for-release'
    lambda_service 'release-monitoring'
    consumer_klass LambdaEventResponses::TagChecksResult
    receiver_job_queue TagsafeQueue.CRITICAL

    def initialize(tag)
      @tag = tag
    end

    def executed_lambda_function_parent
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