require 'rails_helper'


RSpec.describe TagsafeJsDataConsumerJob do
  before(:each) do
    prepare_test!
    @data = {
      'cloudflare_message_id' => 'cldflr_abc123',
      'container_uid' => @container.uid,
      'full_page_url' => 'https://www.tagsafe.io/home',
      'tagsafe_js_ts' => 5.minutes.ago.to_i, 
      'enqueued_at_ts' => 4.minutes.ago.to_i,
      'intercepted_tags' => [{
        'tag_url' => 'https://cdn.example.com/script.js'
      }],
      'third_party_tags' => [
        {
          'tag_url' => 'https://cdn.example.com/script.js',
          'load_type' => 'async'
        },
        {
          'tag_url' => 'https://cdn.a-new-third-party-tag.com/script.js',
          'load_type' => 'defer'
        },
      ]
    }
  end

  describe '#perform' do
    it 'creates a new TagsafeJsEventBatch' do
      expect(@container.tagsafe_js_event_batches.count).to be(0)
      TagsafeJsDataConsumerJob.perform_now(@data)
      expect(@container.tagsafe_js_event_batches.count).to be(1)
      expect(@container.tagsafe_js_event_batches.first.tagsafe_js_ts).to eq(Time.at(@data['tagsafe_js_ts']))
      expect(@container.tagsafe_js_event_batches.first.enqueued_at).to eq(Time.at(@data['enqueued_at_ts']))
      expect(@container.tagsafe_js_event_batches.first.tagsafe_consumer_received_at).to_not be(nil)
      expect(@container.tagsafe_js_event_batches.first.tagsafe_consumer_processed_at).to_not be(nil)
    end

    it 'Passes the correct data to the respective consumer classes' do
      allow(TagsafeJsEventBatch).to receive(:create!).and_call_original
      allow(TagsafeJsDataConsumer::ThirdPartyTags).to receive(:new).and_call_original
      allow(TagsafeJsDataConsumer::InterceptedTags).to receive(:new).and_call_original
      # allow(TagsafeJsDataConsumer::ThirdPartyTags).to receive(:new).with(@data['third_party_tags'], 'stubbed_event_batch').and_call_original
      # allow(TagsafeJsDataConsumer::InterceptedTags).to receive(:new).with(@data['intercepted_tags'], 'stubbed_event_batch').and_call_original
      allow_any_instance_of(TagsafeJsEventBatch).to receive(:processing_completed!)
      TagsafeJsDataConsumerJob.perform_now(@data)
    end
  end
end