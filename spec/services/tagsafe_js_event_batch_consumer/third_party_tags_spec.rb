require 'rails_helper'

RSpec.describe TagsafeJsEventBatchConsumer::ThirdPartyTags do
  before(:each) do
    prepare_test!
    # TODO: this is creating a second Container, why isn't accepting be passed in?
    @tagsafe_js_event_batch = create(:tagsafe_js_event_batch, container: @container)
    @tag_data_arr = [
      {
        'tag_url' => 'https://www.new-tag.com/script.js',
        'load_type' => 'async',
        'intercepted_by_tagsafe_js' => true,
        'optimized_by_tagsafe_js' => false
      }
    ].map{ |data| TagsafeJsEventBatchConsumer::TagData.new(data) }
    @consumer = TagsafeJsEventBatchConsumer::ThirdPartyTags.new(
      container: @container,
      third_party_tags_data: @tag_data_arr,
      tagsafe_js_event_batch: @tagsafe_js_event_batch
    )
  end

  describe '#consume!' do
    it 'creates a new Tag for newly identified tags' do
      expect(@container.tags.count).to eq(0)
      @consumer.consume!
      expect(@container.tags.count).to eq(1)
    end

    it 'new Tags are created with the correct data' do
      @consumer.consume!
      expect(@container.tags.count).to eq(1)
      expect(@container.tags.first.full_url).to eq('https://www.new-tag.com/script.js')
      expect(@container.tags.first.load_type).to eq('async')
      expect(@container.tags.first.tagsafe_js_intercepted_count).to eq(1)
      expect(@container.tags.first.tagsafe_js_not_intercepted_count).to eq(0)
      expect(@container.tags.first.page_urls.count).to eq(1)
      expect(@container.tags.first.page_urls.first).to eq(@tagsafe_js_event_batch.page_url)
    end

    it 'updates already captured Tags with new data' do
      @consumer.consume!
      expect(@container.tags.count).to eq(1)

      tagsafe_js_event_batch_2 = create(:tagsafe_js_event_batch, container: @container)
      consumer_2 = TagsafeJsEventBatchConsumer::ThirdPartyTags.new(
        container: @container,
        third_party_tags_data: @tag_data_arr,
        tagsafe_js_event_batch: tagsafe_js_event_batch_2
      )
      consumer_2.consume!
      expect(@container.tags.count).to eq(1)
      expect(@container.tags.first.full_url).to eq('https://www.new-tag.com/script.js')
      expect(@container.tags.first.load_type).to eq('async')
      expect(@container.tags.first.tagsafe_js_intercepted_count).to eq(2)
      expect(@container.tags.first.tagsafe_js_not_intercepted_count).to eq(0)
      expect(@container.tags.first.page_urls.count).to eq(1)
      expect(@container.tags.first.page_urls.first.full_url).to eq(tagsafe_js_event_batch_2.page_url.full_url)
    end
  end
end