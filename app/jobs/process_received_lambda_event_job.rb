class ProcessReceivedLambdaEventJob < ApplicationJob
  def perform(lambda_event_payload)
    klass = event_results_processor_klass(lambda_event_payload)
    sentry_transaction = Sentry.start_transaction(op: "ProcessReceivedLambdaEventJob #{klass}.process_results!")
    klass.new(lambda_event_payload).process_results!
    sentry_transaction.finish
  end

  def event_results_processor_klass(event_payload)
    lambda_sender_klass = event_payload.dig('detail', 'requestPayload', 'lambda_sender_klass') 
    event_response_klass = {
      'LambdaFunctionInvoker::PerformanceAuditer' => LambdaEventResponses::PerformanceAuditResult,
      'LambdaFunctionInvoker::UrlCrawler' => LambdaEventResponses::UrlCrawlResult,
      'LambdaFunctionInvoker::FunctionalTestRunner' => LambdaEventResponses::TestRunResult,
      'LambdaFunctionInvoker::HtmlSnapshotter' => LambdaEventResponses::HtmlSnapshotResult
    }[lambda_sender_klass]
  end
end