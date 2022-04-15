class ProcessReceivedLambdaEventJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(step_function_results)
    StepFunctionResponses::EventRouter.new(
      step_function_results
    ).route_event_to_respective_step_function_response_and_process!
  end
end