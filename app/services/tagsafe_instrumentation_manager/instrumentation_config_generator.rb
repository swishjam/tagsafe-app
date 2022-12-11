module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(domain)
      @domain = domain
    end

    def write_instrumentation_config_file
      File.write(config_file_location, config_file_content)
      config_file_location
    end

    private

    def config_file_location
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@domain.uid}", 'data', 'config.js')
    end

    def config_file_content
      <<~CONFIG
        export default {
          buildTime: '#{Time.current.formatted_short}',
          disabled: false,
          uid: '#{@domain.uid}',
          tagConfigurations: #{buld_tag_configurations_hash},
          urlPatternsToNotCapture: #{@domain.tag_url_patterns_to_not_capture.collect(&:url_pattern)},
          settings: {
            reportingURL: '#{ENV['TAGSAFE_JS_REPORTING_URL']}',
            sampleRate: 1,
          }
        }
      CONFIG
    end

    def buld_tag_configurations_hash
      js = '{'
      @domain.tags.each_with_index do |tag, i|
        js += <<~JS
          #{tag.full_url}: {
            uid: '#{tag.uid}',
            configuredTagUrl: '#{tag.is_tagsafe_hosted ? tag.current_live_tag_version.js_file_url : nil}',
            sha256: '#{tag.is_tagsafe_hosted ? tag.current_live_tag_version.sha_256 : nil}',
            tagVersion: '#{tag.current_live_tag_version&.uid}'
          },
        JS
      end
      js += '}'
    end
  end
end