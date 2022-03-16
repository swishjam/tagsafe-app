module HasExecutedLambdaFunction
  def self.included(base)
    base.include(InstanceMethods)

    base.before_destroy { executed_lambda_function&.destroy! }
    base.scope :awaiting_lambda_response, -> { where(lambda_response_received_at: nil) }
    base.scope :received_lambda_response, -> { where.not(lambda_response_received_at: nil) }
  end

  module InstanceMethods
    def received_lambda_response!(response_payload:, response_code: 202)
      touch(:lambda_response_received_at)
      unless executed_lambda_function.nil?
        executed_lambda_function.response_received!(
          response_payload: response_payload, 
          response_code: response_code
        )
      end
    end

    def received_lambda_response?
      lambda_response_received_at.present?
    end

    def executed_lambda_function
      ExecutedLambdaFunction.for(self)
    end
  end
end