module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(domain, config_file_name: 'config.js')
      @domain = domain
      @config_file_name = config_file_name
    end

    def write_instrumentation_config_file
      File.write(config_file_location, config_file_content)
      config_file_location
    end

    private

    def config_file_location
      Rails.root.join('tagsafe-instrumentation', 'data', @config_file_name)
    end

    def config_file_content
      "
        export default {
          buildTime: '#{Time.current.formatted_short}',
          tagsToInjectImmediately: #{build_array_of_tag_configs(
            @domain.tags.includes(:live_tag_configuration).where_live_tag_configuration(enabled: true, script_inject_location: 'head')
          )},
          tagsToInjectOnLoad: #{build_array_of_tag_configs(
            @domain.tags.includes(:live_tag_configuration).where_live_tag_configuration(enabled: true, script_inject_location: 'body')
          )},
          disabledTags: #{@domain.tags.where_live_tag_configuration(enabled: false).collect(&:full_url)}
        }
      "
    end

    def build_array_of_tag_configs(tags)
      js = '['
      tags.each_with_index do |tag, i|
        js += "
          {
            #{tag.has_js_script? ? "'_': '#{tag.js_script_fingerprint}'," : nil}
            'el': 'script',
            'uid': '#{tag.uid}',
            'directTagUrl': '#{tag.has_url? ? tag.full_url : nil}',
            'tagsafeHostedTagUrl': '#{tag.live_tag_configuration.is_tagsafe_hosted ? tag.current_live_tag_version.js_file_url : nil}',
            'loadRule': '#{tag.live_tag_configuration.load_type || 'defer'}',
            'script': `#{tag.has_js_script? ? tag.js_script_content(sanitize: true) : nil}`,
            'injectLocation': '#{tag.live_tag_configuration.script_inject_location}',
            'injectAt': '#{tag.live_tag_configuration.script_inject_event}',
            'sha256': '#{tag.has_url? && tag.live_tag_configuration.is_tagsafe_hosted ? tag.current_live_tag_version.sha_256 : nil}',
            'tag_version': '#{tag.current_live_tag_version&.uid}'
          }
        "
        js += ", " unless tags.count - 1 == i
      end
      js += ']'
    end
  end
end