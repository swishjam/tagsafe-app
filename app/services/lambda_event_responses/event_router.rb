module LambdaEventResponses
  class EventRouter
    attr_accessor :lambda_event_payload

    def initialize(lambda_event_payload)
      # TODO: when is the event payload `requestPayload` and `responsePayload` nested in `detail` vs root?
      @lambda_event_payload = lambda_event_payload.dig('detail') || lambda_event_payload
    end

    def route_event_to_respective_lambda_event_response_and_process!
      if event_results_processor.record.received_lambda_response?
        Rails.logger.warn "LambdaEventResponses::EventRouter - Received response for #{event_results_processor.record.uid} that was already received, skipping processing...."
      else
        process_result!
      end
    end

    private

    def process_result!
      start_time = Time.now
      Rails.logger.info "Beginning ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! ......"
      event_results_processor.record.received_lambda_response!(response_payload: lambda_event_payload['responsePayload'])
      event_results_processor.process_results!
      Rails.logger.info "Completed ProcessReceivedLambdaEventJob #{event_results_processor_klass}.process_results! in #{Time.now - start_time} seconds"
    end

    def executed_lambda_function
      @executed_lambda_function ||= ExecutedLambdaFunction.find(id: lambda_event_payload.dig('requestPayload', 'executed_lambda_function_id'))
    end

    def event_results_processor
      @event_results_processor ||= event_results_processor_klass.new(lambda_event_payload)
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