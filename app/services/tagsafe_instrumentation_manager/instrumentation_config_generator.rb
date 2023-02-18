module TagsafeInstrumentationManager
  class InstrumentationConfigGenerator
    def initialize(container)
      @container = container
      @tags = container.tags.includes(:current_live_tag_version)
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
          tagInterceptionRules: #{build_tag_interceptions_hash},
          tagConfigurations: {
            immediate: #{build_tag_configurations_hash},
            onLoad: [],
          },
          settings: {
            reportingURL: '#{ENV['TAGSAFE_JS_REPORTING_URL']}',
            reRouteEligibleTagsSampleRate: #{@container.tagsafe_js_re_route_eligible_tags_sample_rate},
            reportingSampleRate: #{@container.tagsafe_js_reporting_sample_rate},
          }
        }
      CONFIG
    end

    def build_tag_configurations_hash
      js = "["
      @container.tag_snippets.in_live_state.each do |tag_snippet|
        html_content = tag_snippet.content.download
        js += "
          {
            uid: '#{tag_snippet.uid}',
            content: '#{tag_snippet.encoded_content}',
            injectUrls: #{build_tag_snippet_inject_array(tag_snippet, :inject_rules) == '[]' ? "\"*\"" : build_tag_snippet_inject_array(tag_snippet, :inject_rules)},
            ignoreUrls: #{build_tag_snippet_inject_array(tag_snippet, :dont_inject_rules)},
          },
        "
      end
      js += "]"
    end
    
    def build_tag_interceptions_hash
      js = '{'
      @container.tags.each do |tag|
        js += "
          '#{tag.full_url}': {
            tag: '#{tag.uid}',
            tagVersion: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.uid}\"" : 'null'},
            configuredTagUrl: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.js_file_url}\"" : 'null'},
            configuredLoadType: #{"\"#{tag.configured_load_strategy_based_on_preferences}\""},
            sha256: #{tag.is_tagsafe_hosted && tag.has_current_live_tag_version? ? "\"#{tag.current_live_tag_version.sha_256}\"" : 'null'},
          },
        "
      end
      js += '}'
    end

    # def configured_load_type_for_tag(tag)
    #   return "\"defer\"" if @container.defer_script_tags_by_default && tag.configured_load_type == 'default'
    #   "\"#{tag.configured_load_type}\""
    # end

    def build_tag_snippet_inject_array(tag_snippet, tag_inject_scope)
      js = '['
      tag_snippet.injection_url_rules.send(tag_inject_scope).each do |inject_rule| 
        js += "{ urlPattern: '#{inject_rule.url}' }"
      end
      js += ']'
    end
  end
end