module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(domain, config_file_name: 'config.js')
      @domain = domain
      @config_file_name = config_file_name
    end

    def write_instrumentation_config_file
      File.write(config_file_location, config_file_content)
    end

    private

    def config_file_location
      Rails.root.join('tagsafe-instrumentation', 'data', @config_file_name)
    end

    def config_file_content
      "
        export default {
          buildTime: '#{Time.current.formatted_short}',
          tagsToInjectImmediately: #{build_array_of_tag_configs(@domain.tags.script_injection_enabled.injected_in_head)},
          tagsToInjectOnLoad: #{build_array_of_tag_configs(@domain.tags.script_injection_enabled.injected_in_body)},
          disabledTags: #{@domain.tags.script_injection_disabled.collect(&:full_url)}
        }
      "
    end

    def build_array_of_tag_configs(tags)
      js = '['
      tags.each_with_index do |tag, i|
        js += "
          {
            'directTagUrl': '#{tag.full_url}',
            'tagsafeHostedTagUrl': '#{tag.tag_versions.last&.js_file_url}',
            'loadRule': '#{tag.load_type || 'defer'}',
            'el': 'script',
            'injectLocation': '#{tag.script_inject_location}',
            'injectAt': '#{tag.inject_script_at_event}',
            'sri': 'sha256-#{tag.tag_versions.last&.sha_256}'
          }
        "
        js += ", " unless tags.count - 1 == i
      end
      js += ']'
    end
  end
end