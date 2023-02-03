class TagsafeJsDataConsumerJob < ApplicationJob
  class TagsafeJsInstrumentationError < StandardError; end
  # we don't need to define a queue here because it's queue is defined in the Cloudflare producer
  # queue_as TagsafeQueue.TAGSAFE_JS_EVENTS

  def perform(data)
    if data['is_error_report']
      (data['errors'] || []).each do |error_msg|
        begin
          raise TagsafeJsInstrumentationError, error_msg
        rescue => e
          Sentry.capture_exception(e)
        end
      end
    else
      payload_parser = TagsafeJsDataConsumer::PayloadParser.new(data)
      TagsafeJsDataConsumer::PerformanceMetrics.new(payload_parser).consume!
      payload_parser.page_load.processing_completed!
    end
  end
end