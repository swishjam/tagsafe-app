module ChartHelper
  class TagData
    def initialize(tag:, start_time:, end_time:, metric:)
      @tag = tag
      @metric_key = metric
      @start_time = start_time
      @end_time = end_time
      @chart_data_for_provided_metric = { name: tooltip_title, data: [] }
    end
    
    def chart_data
      format_chart_data!
    end

    def tooltip_title
      @metric_key.to_s.gsub('delta', '').strip.split('_').map(&:capitalize).join(' ')
    end

    private

    def format_chart_data!
      add_current_timestamp_to_chart_data
      add_tags_primary_delta_performance_audits
      add_starting_timestamps_if_necessary
      [@chart_data_for_provided_metric]
    end

    def add_current_timestamp_to_chart_data
      current_primary_audit = @tag.current_version&.primary_audit || @tag.current_version&.previous_version&.primary_audit
      unless current_primary_audit.nil?
        @chart_data_for_provided_metric[:data] << [DateTime.now, current_primary_audit.average_delta_performance_audit[@metric_key]]
      end
    end

    def add_tags_primary_delta_performance_audits
      @performance_audits ||= AverageDeltaPerformanceAudit.includes(audit: :tag_version)
                                                            .where(audits: { tag_id: @tag.id, primary: true, throttled: false })
                                                            .more_recent_than_or_equal_to(@start_time, timestamp_column: 'tag_versions.created_at')
                                                            .older_than_or_equal_to(@end_time, timestamp_column: 'tag_versions.created_at')
                                                            .order('tag_versions.created_at ASC').each do |delta_performance_audit|
        @chart_data_for_provided_metric[:data] << [delta_performance_audit.audit.tag_version.created_at, delta_performance_audit[@metric_key]]
      end
    end

    def add_starting_timestamps_if_necessary
      unless @tag.first_version.created_at > @start_time
        @chart_data_for_provided_metric[:data] << [@start_time, @chart_data_for_provided_metric[:data].last[1]]
      end
    end
  end
end