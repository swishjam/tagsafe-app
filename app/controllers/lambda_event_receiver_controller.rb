class LambdaEventReceiverController < ApplicationController
  skip_before_action :verify_authenticity_token

  def success
  #   ProcessReceivedLambdaEventJob.perform_later(JSON.parse(params['lambda_event_receiver'].to_json))
  #   head :ok
  # rescue => e
  #   Sentry.capture_exception(e)
    head :internal_server_error
  end
end