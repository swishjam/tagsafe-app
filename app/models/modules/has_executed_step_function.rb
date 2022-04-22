module HasExecutedStepFunction
  def self.included(base)
    base.include(InstanceMethods)

    base.before_destroy { executed_step_function&.destroy! }
    base.scope :awaiting_lambda_response, -> { where(lambda_response_received_at: nil) }
    base.scope :received_lambda_response, -> { where.not(lambda_response_received_at: nil) }
  end

  module InstanceMethods
    def received_lambda_response!(response_payload:, error_message: nil, response_code: 202)
      Rails.logger.warn "ExecutedStepFunction - parent received multiple responses for #{uid}, continuing with new data..." if received_lambda_response?
      touch(:lambda_response_received_at)
      unless executed_step_function.nil?
        executed_step_function.response_received!(
          response_payload: response_payload, 
          response_code: response_code,
          error_message: error_message
        )
      end
    end

    def received_lambda_response?
      lambda_response_received_at.present?
    end

    def executed_step_function
      ExecutedStepFunction.for(self)
    end
  end
end