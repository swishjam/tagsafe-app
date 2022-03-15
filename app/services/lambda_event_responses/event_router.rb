module LambdaEventResponses
  class EventRouter
    attr_accessor :lambda_event_payload

    def initialize(lambda_event_payload)
      # TODO: when is the event payload `requestPayload` and `responsePayload` nested in `detail` vs root?
      @lambda_event_payload = lambda_event_payload.dig('detail') || lambda_event_payload
    end

    def route_event_to_respective_lambda_event_response_and_process!
      if executed_lambda_function.nil?
        Rails.logger.warn "Received Lambda Response without an ExecutedLambdaFunction.\nsource: #{lambda_event_payload['source']}, detail-type: #{lambda_event_payload['detail-type']}"
      elsif executed_lambda_function.already_received_response?
        Rails.logger.warn "Received response for ExecutedLambdaFunction #{executed_lambda_function.id} (#{executed_lambda_function.parent_type} Parent #{executed_lambda_function.parent_id}) that was already received, skipping processing...."
      else
        process_result!
      end
    end

    private

    def process_result!
      start_time = Time.now
      Rails.logger.info "Beginning ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! ......"
      sentry_transaction = Sentry.start_transaction(op: "ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results!")
      executed_lambda_function.response_received!(response_payload: lambda_event_payload['responsePayload'])
      event_results_processor_klass.new(lambda_event_payload).process_results!
      Rails.logger.info "Completed ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! in #{Time.now - start_time} seconds"
      sentry_transaction.finish
    end

    def executed_lambda_function
      @executed_lambda_function ||= ExecutedLambdaFunction.find_by(id: lambda_event_payload.dig('requestPayload', 'executed_lambda_function_id'))
    end

    def event_results_processor_klass
      @event_results_processor_klass ||= {
        LambdaFunctionInvoker::PerformanceAuditer => LambdaEventResponses::PerformanceAuditResult,
        LambdaFunctionInvoker::UrlCrawler => LambdaEventResponses::UrlCrawlResult,
        LambdaFunctionInvoker::FunctionalTestRunner => LambdaEventResponses::TestRunResult,
        LambdaFunctionInvoker::HtmlSnapshotter => LambdaEventResponses::HtmlSnapshotResult
      }[lambda_function_invoker_klass]
    end

    def lambda_function_invoker_klass
      @lambda_function_invoker_klass ||= lambda_event_payload.dig('requestPayload', 'lambda_invoker_klass').constantize
    end
  end
end