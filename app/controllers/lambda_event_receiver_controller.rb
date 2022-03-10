class LambdaEventReceiverController < ApplicationController
  skip_before_action :verify_authenticity_token

  def success
    elf = ExecutedLambdaFunction.find(params.dig('lambda_event_receiver', 'detail', 'requestPayload', 'executed_lambda_function_id'))
    elf.response_received!(response_payload: JSON.parse(params['lambda_event_receiver'].to_json))
    head :ok
  end
end