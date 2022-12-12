require 'rails_helper'

RSpec.describe TagsafeJsEventBatchConsumer::PayloadParser do
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

  describe '#page_url' do
    it 'creates a new page_url for the Container if one does not yet exist for the provided URL' do
      expect(@container.page_urls.count).to be(0)
      parser = TagsafeJsEventBatchConsumer::PayloadParser.new(@data)
      expect(@container.page_urls.count).to be(1)
    end

    it 'finds the existing page_url for the Container if one already exists for the provided URL' do
      create(:page_url, container: @container, full_url: @data['full_page_url'])
      expect(@container.page_urls.count).to be(1)
      parser = TagsafeJsEventBatchConsumer::PayloadParser.new(@data)
      expect(@container.page_urls.count).to be(1)
    end
  end

  describe '#tagsafe_js_event_batch' do
    it 'creates a new TagsafeJsEventBatch' do
      parser = TagsafeJsEventBatchConsumer::PayloadParser.new(@data)
      expect(parser.tagsafe_js_event_batch.tagsafe_js_ts).to eq(Time.at(@data['tagsafe_js_ts']))
      expect(parser.tagsafe_js_event_batch.enqueued_at).to eq(Time.at(@data['enqueued_at_ts']))
    end
  end

  describe '#intercepted_tags' do
    it 'initializes an array of TagData objects from the provided data' do
      parser = TagsafeJsEventBatchConsumer::PayloadParser.new(@data)
      expect(parser.intercepted_tags.count).to eq(1)
      expect(parser.intercepted_tags[0].url).to eq('https://cdn.example.com/script.js')
    end

    it 'filters out duplicate URLs' do
      @data['intercepted_tags'] << @data['intercepted_tags'][0]
      parser = TagsafeJsEventBatchConsumer::PayloadParser.new(@data)
      expect(parser.intercepted_tags.count).to eq(1)
      expect(parser.intercepted_tags[0].url).to eq('https://cdn.example.com/script.js')
    end
  end
end