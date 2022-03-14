class ProcessReceivedLambdaEventJob < ApplicationJob
  def perform(lambda_event_payload)
    LambdaEventResponses::EventRouter.new(
      lambda_event_payload
    ).route_event_to_respective_lambda_event_response_and_process!
  end
end