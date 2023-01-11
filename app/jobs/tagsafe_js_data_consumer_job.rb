class TagsafeJsDataConsumerJob < ApplicationJob
  def perform(data)
    payload_parser = TagsafeJsDataConsumer::PayloadParser.new(data)
    TagsafeJsDataConsumer::PerformanceMetrics.new(payload_parser).consume!
    payload_parser.page_load.processing_completed!
  end
end