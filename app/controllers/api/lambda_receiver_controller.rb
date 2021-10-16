module Api
  class LambdaReceiverController < BaseController
    def success_receiver
      receive!(true)
    end

    def fail_receiver
      receive!(false)
    end

    private

    def receive!(success)
      job_class = success ? SuccessfulLambdaFunctionReceiverJob : FailedLambdaFunctionReceiverJob
      job_class.perform_later(JSON.parse(params.to_json)['responsePayload'])
      render json: { success: true }, status: 200
    end
  end
end