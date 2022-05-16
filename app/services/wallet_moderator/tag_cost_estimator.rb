module WalletModerator
  class TagCostEstimator
    def initialize(tag)
      @tag = tag
    end

    def total_credits_per_month
      release_monitoring_credits_per_month +
        uptime_monitoring_credits_per_month +
        automated_performance_audit_credits_per_month +
        automated_test_run_credits_per_month
    end

    def release_monitoring_credits_per_month
      @release_monitoring_credits_per_month ||= begin
        return 0 unless @tag.release_monitoring_enabled?
        num_checks_per_day = 1_440 / @tag.tag_preferences.release_check_minute_interval
        num_checks_per_day * 30 * feature_prices.release_check_price
      end
    end

    def uptime_monitoring_credits_per_month
      @uptime_monitoring_credits_per_month ||= begin
        return 0 unless @tag.uptime_monitoring_enabled?
        @tag.uptime_regions.count * 1_440 * 30 * feature_prices.release_check_price
      end
    end

    def automated_performance_audit_credits_per_month
      @automated_performance_audit_credits_per_month ||= begin
        return 0 unless @tag.scheduled_audits_enabled? && automated_audit_settings.include_performance_audit
        price = feature_prices.automated_performance_audit_price
        price += feature_prices.speed_index_filmstrip_price
        price += feature_prices.puppeteer_recording_price if automated_audit_settings.perf_audit_enable_screen_recording 
        price += feature_prices.resource_waterfall_price if automated_audit_settings.include_page_load_resources
        scheduled_audits_per_day = 1_440 / @tag.tag_preferences.scheduled_audit_minute_interval
        price * @tag.urls_to_audit.count * 30 * scheduled_audits_per_day
      end
    end

    def automated_test_run_credits_per_month
      @automated_test_run_credits_per_month ||= begin
        return 0 unless @tag.scheduled_audits_enabled? && automated_audit_settings.include_functional_tests
        price_per_test_suite = feature_prices.automated_test_run_price * @tag.functional_tests.count
        scheduled_audits_per_day = 1_440 / @tag.tag_preferences.scheduled_audit_minute_interval
        price_per_test_suite * 30 * scheduled_audits_per_day
      end
    end

    private

    def automated_audit_settings
      @automated_audit_settings ||= @tag.tag_or_domain_configuration
    end

    def feature_prices
      @feature_prices ||= @tag.domain.feature_prices_in_credits
    end
  end
end