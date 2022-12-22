module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(container)
      @container = container
      @tagsafe_hosted_tags = container.tags.includes(:current_live_tag_version).tagsafe_hosted
      @tag_url_patterns_to_not_capture = container.tag_url_patterns_to_not_capture
    end

    def write_instrumentation_config_file
      File.write(config_file_location, config_file_content)
      config_file_location
    end

    private

    def config_file_location
      Rails.root.join('tmp', "tagsafe-instrumentation-#{@container.uid}", 'data', 'config.js')
    end

    def config_file_content
      <<~CONFIG
        export default {
          uid: '#{@container.uid}',
          buildTime: '#{Time.current.formatted_short}',
          disabled: #{!@container.tagsafe_js_enabled},
          tagConfigurations: #{buld_tag_configurations_hash},
          urlPatternsToNotCapture: #{@tag_url_patterns_to_not_capture.collect(&:url_pattern)},
          settings: {
            reportingURL: '#{ENV['TAGSAFE_JS_REPORTING_URL']}',
            sampleRate: #{@container.tagsafe_js_reporting_sample_rate},
          }
        }
      CONFIG
    end

    def buld_tag_configurations_hash
      js = '{'
      @tagsafe_hosted_tags.each do |tag|
        js += "
          '#{tag.full_url}': {
            tag: '#{tag.uid}',
            tagVersion: '#{tag.current_live_tag_version.uid}',
            configuredTagUrl: '#{configured_tag_url(tag)}',
            sha256: '#{configured_sha_256_for_tag(tag)}',
          },
        "
      end
      js += '}'
    end

    def should_optimize_tag?(tag)
      tag.is_tagsafe_hosted && tag.current_live_tag_version.present?
    end

    def configured_tag_url(tag)
      return nil unless tag.is_tagsafe_hosted && tag.current_live_tag_version
      tag.current_live_tag_version.js_file_url
    end

    def configured_sha_256_for_tag(tag)
      return nil unless tag.is_tagsafe_hosted && tag.current_live_tag_version
      tag.current_live_tag_version.sha_256
    end
  end
end