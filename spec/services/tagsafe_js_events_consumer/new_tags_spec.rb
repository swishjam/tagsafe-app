require 'rails_helper'

RSpec.describe TagsafeJsEventsConsumer::NewTags do
  before(:each) do
    prepare_test!
    @tag = create_tag_with_associations
    @data = {
      'domain_uid' => @container.uid,
      'cloudflare_message_id' => 'cldflr_xyz123',
      'new_tags' => [{
        'tag_url' => 'https://cdn.example.com/script.js',
        'load_type' => 'async',
        'page_url_found_on' => 'https://www.test.com/home'
      }],
      'intercepted_tags' => [{ 'tag_url' => @tag.full_url }],
      'warnings' => [],
      'errors' => []
    }
    @consumer = TagsafeJsEventsConsumers::NewTags.new(@data)
  end

  describe '#consume!' do
    it 'Creates a new NewTagsIdentifiedBatch' do
      expect(@container.tagsafe_js_event_batches.count).to be(1)
      @consumer.consume!
      expect(@container.tagsafe_js_event_batches.count).to be(2)
    end

    it 'updates existing tags from the provided `identified_tags` data' do
      og_last_seen_at = @tag.last_seen_at
      sleep 1
      @consumer.consume!
      expect(og_last_seen_at).to_not eq(@tag.reload.last_seen_at)
    end

    it 'creates new tags from the provided `new_tags` data if they do not yet exist' do
      expect(@container.tags.count).to be(1)
      expect(@container.tags.collect(&:full_url)).to_not include('https://cdn.example.com/script.js')
      
      @consumer.consume!

      @container.tags.reload
      expect(@container.tags.count).to be(2)
      expect(@container.tags.collect(&:full_url)).to include('https://cdn.example.com/script.js')
    end

    it 'does not create a new tag from if the URL in the `new_tags` data already exists' do
      expect(@container.tags.count).to be(1)
      @data['new_tags'][0]['tag_url'] = @container.tags.first.full_url
      
      TagsafeJsEventsConsumers::NewTags.new(@data).consume!

      @container.tags.reload
      expect(@container.tags.count).to be(1)
    end

    it 'adds the new Tag URL to the domain\'s `tag_url_patterns_to_not_capture` if it exceeds the max number of tags for that URL' do
      stub_const('ENV', ENV.to_hash.merge('MAX_NUM_TAGS_FOR_SAME_URL' => '1'))

      expect(@container.tags.count).to be(1)
      expect(@container.tag_url_patterns_to_not_capture.count).to be(0)
      
      @data['new_tags'][0]['tag_url'] = "#{@container.tags.first.full_url}?a_query_param_that_makes_this_a_new_url=true"
      TagsafeJsEventsConsumers::NewTags.new(@data).consume!

      @container.tags.reload
      expect(@container.tags.count).to be(1)
      expect(@container.tag_url_patterns_to_not_capture.collect(&:url_pattern)).to eq(["#{@tag.url_hostname}#{@tag.url_path}"])
    end

    it 're-builds instrumentation if a new tag was added' do
      expect(@container.tags.count).to eq(1)
      allow_any_instance_of(TagsafeInstrumentationManager::InstrumentationWriter).to receive(:write_current_instrumentation_to_cdn).exactly(:once)
      @consumer.consume!
      expect(@container.reload.tags.count).to eq(2)
    end

    it 're-builds instrumentation if a `tag_url_pattern_to_not_capture` was added' do
      allow_any_instance_of(TagsafeInstrumentationManager::InstrumentationWriter).to receive(:write_current_instrumentation_to_cdn).exactly(:once)
      stub_const('ENV', ENV.to_hash.merge('MAX_NUM_TAGS_FOR_SAME_URL' => '1'))

      expect(@container.tags.count).to be(1)
      expect(@container.tag_url_patterns_to_not_capture.count).to be(0)
      
      @data['new_tags'][0]['tag_url'] = "#{@container.tags.first.full_url}?a_query_param_that_makes_this_a_new_url=true"
      TagsafeJsEventsConsumers::NewTags.new(@data).consume!

      @container.reload
      expect(@container.tags.count).to be(1)
      expect(@container.tag_url_patterns_to_not_capture.count).to be(1)
    end

    it 'does not re-build instrumentation if a new tag was not added and a `tag_url_pattern_to_not_capture` was not added' do
      @data['new_tags'] = []
      expect_any_instance_of(TagsafeInstrumentationManager::InstrumentationWriter).to_not receive(:write_current_instrumentation_to_cdn)
      expect(@container.tags.count).to eq(1)
      expect(@container.tag_url_patterns_to_not_capture.count).to eq(0)

      TagsafeJsEventsConsumers::NewTags.new(@data).consume!
      
      @container.reload
      expect(@container.tags.count).to eq(1)
      expect(@container.tag_url_patterns_to_not_capture.count).to eq(0)
    end
  end
end