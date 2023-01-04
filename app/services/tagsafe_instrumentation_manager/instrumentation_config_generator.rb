module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(container)
      @container = container
      @tags = container.tags.includes(:current_live_tag_version)
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
          tagConfigurations: #{buld_tag_configurations_hash},
          settings: {
            reportingURL: '#{ENV['TAGSAFE_JS_REPORTING_URL']}',
            sampleRate: #{@container.tagsafe_js_reporting_sample_rate},
          }
        }
      CONFIG
    end

    def buld_tag_configurations_hash
      js = '{'
      @tags.each do |tag|
        js += "
          '#{tag.full_url}': {
            tag: '#{tag.uid}',
            tagVersion: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.uid}\"" : 'null'},
            configuredTagUrl: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.js_file_url}\"" : 'null'},
            configuredLoadType: #{configured_load_type_for_tag(tag)},
            sha256: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.sha_256}\"" : 'null'},
          },
        "
      end
      js += '}'
    end

    def configured_load_type_for_tag(tag)
      return "\"defer\"" if @container.defer_script_tags_by_default && tag.configured_load_type == 'default'
      "\"#{tag.configured_load_type}\""
    end
  end
end