require 'rails_helper'

RSpec.describe TagsafeInstrumentationManager::InstrumentationConfigGenerator do
  before(:each) do
    prepare_test!
    @tag = create_tag_with_associations
  end

  describe '#write_instrumentation_config_file' do
    it 'writes the correct content to the config file' do
      frozen_time = Time.current
      stub_const('ENV', ENV.to_hash.merge('TAGSAFE_JS_REPORTING_URL' => 'https://api.tagsafe.io/reporting'))
      allow(Time).to receive(:current).and_return(frozen_time)

      expected_config_file_path = Rails.root.join('tmp', "tagsafe-instrumentation-#{@container.uid}", 'data', 'config.js')
      expected_config_file_content = <<~CONFIG
        export default {
          buildTime: '#{frozen_time.formatted_short}',
          disabled: false,
          uid: '#{@container.uid}',
          tagConfigurations: {
            #{@tag.full_url}: {
              uid: '#{@tag.uid}',
              configuredTagUrl: '#{@tag.current_live_tag_version.js_file_url}',
              sha256: '#{@tag.current_live_tag_version.sha_256}',
              tagVersion: '#{@tag.current_live_tag_version.uid}'
            },
          },
          urlPatternsToNotCapture: [],
          settings: {
            reportingURL: 'https://api.tagsafe.io/reporting',
            sampleRate: 1,
          }
        }
      CONFIG
      
      allow(File).to receive(:write).with(expected_config_file_path, expected_config_file_content).exactly(:once)
      TagsafeInstrumentationManager::InstrumentationConfigGenerator.new(@container).write_instrumentation_config_file
    end
  end
end