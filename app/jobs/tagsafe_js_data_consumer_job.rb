class TagsafeJsDataConsumerJob < ApplicationJob
  def perform(data)
    payload_parser = TagsafeJsDataConsumer::PayloadParser.new(data)
    
    # TODO: only record third party tags not deployed by TagsafeJS
    # third_party_tags_consumer = TagsafeJsDataConsumer::ThirdPartyTags.new(
    #   container: payload_parser.container,
    #   page_load: payload_parser.page_load,
    #   third_party_tags_data: payload_parser.third_party_tags, 
    # )
    # third_party_tags_consumer.consume!

    TagsafeJsDataConsumer::PerformanceMetrics.new(
      container: payload_parser.container,
      page_load: payload_parser.page_load,
      performance_metrics: payload_parser.performance_metrics
    ).consume!

    payload_parser.page_load.processing_completed!

    # return if third_party_tags_consumer.num_updates.zero?
    # payload_parser.container.publish_instrumentation!
  end
end