module LambdaCronJobDataStore
  class ScheduledAudits
    REDIS_KEY = 'scheduled_audit_configurations'.freeze

    def initialize(tag)
      @tag = tag
      @global_scheduled_audit_config = previous_data_store_config_or_default_config
    end

    def self.current_config
      LambdaCronJobDataStore::Redis.client.get(REDIS_KEY)
    end

    def update_data_store_for_tag
      remove_previous_scheduled_audit_config_from_previous_data_store_config
      update_previous_data_store_config_with_new_scheduled_audit_config
      LambdaCronJobDataStore::Redis.client.set(REDIS_KEY, @global_scheduled_audit_config.to_json)
      @global_scheduled_audit_config
    end

    private

    def remove_previous_scheduled_audit_config_from_previous_data_store_config
      TagPreference.SUPPORTED_SCHEDULED_AUDIT_INTERVALS.each do |interval|
        scheduled_audit_config = @global_scheduled_audit_config[interval.to_s][@tag.id.to_s]
        next unless scheduled_audit_config.present?
        @global_scheduled_audit_config[interval.to_s].delete(@tag.id.to_s)
        break
      end
    end

    def update_previous_data_store_config_with_new_scheduled_audit_config
      return if @tag.tag_preferences.scheduled_audits_disabled?
      @global_scheduled_audit_config[@tag.tag_preferences.scheduled_audit_minute_interval.to_s][@tag.id.to_s] = constructed_scheduled_audit_config
    end

    def previous_data_store_config_or_default_config
      previous_config = self.class.current_config
      return JSON.parse(previous_config) unless previous_config.nil?
      JSON.parse(TagPreference.SUPPORTED_SCHEDULED_AUDIT_INTERVALS.map{ |key| [key.to_s, {} ] }.to_h.to_json)
    end

    def constructed_scheduled_audit_config
      {
        page_urls_to_perform_audit_on: @tag.urls_to_audit.collect{ |url_to_audit| url_to_audit.page_url.full_url },
        first_party_request_url: @tag.domain.parsed_domain_url,
        current_tag_version_url: @tag.current_version&.js_file&.url,
        injected_tag_load_type: @tag.load_type,
        # third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: @tag.domain.non_third_party_url_patterns.collect(&:pattern),
        # cached_responses_s3_key: @audit.performance_audit_configuration.cached_responses_s3_key,
        options: {
          override_initial_html_request_with_manipulated_page: default_audit_configuration.perf_audit_override_initial_html_request_with_manipulated_page.to_s,
          # puppeteer_page_wait_until: 'networkidle2',
          puppeteer_page_timeout_ms: 0,
          enable_screen_recording: default_audit_configuration.perf_audit_enable_screen_recording.to_s,
          throw_error_if_dom_complete_is_zero: default_audit_configuration.perf_audit_throw_error_if_dom_complete_is_zero.to_s,
          include_page_load_resources: default_audit_configuration.include_page_load_resources.to_s,
          include_page_tracing: default_audit_configuration.perf_audit_enable_screen_recording.to_s,
          inline_injected_script_tags: default_audit_configuration.perf_audit_inline_injected_script_tags.to_s,
          scroll_page: default_audit_configuration.perf_audit_scroll_page.to_s,
          strip_all_images: default_audit_configuration.perf_audit_strip_all_images.to_s,
          strip_all_css: false.to_s
        }
      }
    end

    def default_audit_configuration
      @default_audit_configuration ||= @tag.default_audit_configuration || @tag.domain.default_audit_configuration
    end
  end
end