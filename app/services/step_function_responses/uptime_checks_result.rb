module StepFunctionResponses
  class UptimeChecksResult
    def initialize(lambda_response)
      @lambda_response = lambda_response
    end

    def process_results!
      create_uptime_check_batch
      UptimeCheck.insert_all!(uptime_check_results_formatted_for_insert) unless uptime_check_results.none?
      uptime_check_batch.touch(:processing_completed_at)
    end

    def uptime_check_results_formatted_for_insert
      uptime_check_results.map(&:formatted_for_create)
    end

    def uptime_check_results
      @release_check_results ||= @lambda_response['uptime_check_results'].map do |result_hash| 
        UptimeCheckResult.new(
          result_hash, 
          aws_region: @lambda_response['aws_region'], 
          uptime_check_batch_id: uptime_check_batch.id
        )
      end
    end

    def uptime_check_batch
      @uptime_check_batch ||= UptimeCheckBatchResult.new(@lambda_response).create_uptime_check_batch!
    end
    alias create_uptime_check_batch uptime_check_batch

    def self.has_executed_step_function?
      false
    end
  end
end