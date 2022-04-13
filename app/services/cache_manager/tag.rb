module CacheManager
  class Tag
    def initialize(tag)
      @tag = tag
    end

    def update_performance_chart_cache!
    end

    def update_uptime_chart_cache!
      Rails.cache.write("#{@tag.uid}_uptime_chart_data", )
    end

    def update_cache!
      Rails.cache.write("#{@tag.cache_key}_current_audit", audit_to_display_data_cache)
    end

    private

    def audit_to_display_data_cache
      {
        include_performance_audit: audit_to_display&.include_performance_audit,
        performance_audit_pending: audit_to_display&.performance_audit_pending?,
        tagsafe_score: audit_to_display&.tagsafe_score,
      }
    end

    def audit_to_display
      @audit_to_display ||= @tag.audit_to_display
    end
  end
end