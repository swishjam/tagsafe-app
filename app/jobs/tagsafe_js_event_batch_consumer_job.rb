class TagsafeJsEventBatchConsumerJob < ApplicationJob
  def perform(data)
    payload_parser = TagsafeJsEventBatchConsumer::PayloadParser.new(data)
    
    third_party_tags_consumer = TagsafeJsEventBatchConsumer::ThirdPartyTags.new(
      container: payload_parser.container,
      third_party_tags_data: payload_parser.third_party_tags, 
      tagsafe_js_event_batch: payload_parser.tagsafe_js_event_batch
    )
    third_party_tags_consumer.consume!
    payload_parser.tagsafe_js_event_batch.processing_completed!

    return if third_party_tags_consumer.num_updates.zero?
    payload_parser.container.publish_instrumentation!
  end
end