module StepFunctionResponses
  class UptimeChecksResult
    def initialize(lambda_response)
      @lambda_response = lambda_response
    end

    def process_results!
      UptimeCheck.insert_all!(uptime_check_results_formatted_for_insert)
    end

    def uptime_check_results_formatted_for_insert
      uptime_check_results.map(&:formatted_for_create)
    end

    def uptime_check_results
      @release_check_results ||= @lambda_response['uptime_check_results'].map{ |res| UptimeCheckResult.new(res, aws_region: @lambda_response['aws_region']) }
    end

    def self.has_executed_step_function?
      false
    end
  end
end