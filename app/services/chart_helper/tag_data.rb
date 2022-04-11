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
      add_audit_data_within_timestamps
      add_starting_timestamps_if_necessary
      [@chart_data_for_provided_metric]
    end

    def add_current_timestamp_to_chart_data
      current_audit = @tag.audit_to_display
      unless current_audit.nil? || current_audit.performance_audit_pending? || current_audit.performance_audit_failed?
        @chart_data_for_provided_metric[:data] << [DateTime.now, current_audit.preferred_delta_performance_audit[@metric_key]]
      end
    end

    def add_audit_data_within_timestamps
      if @tag.should_roll_up_audits_by_tag_version?
        add_tags_primary_delta_performance_audits
      else
        add_all_audits_from_within_timestamps
      end
    end

    def add_tags_primary_delta_performance_audits
      AverageDeltaPerformanceAudit.includes(audit: :tag_version)
                                    .where(audits: { tag_id: @tag.id, primary: true, throttled: false })
                                    .more_recent_than_or_equal_to(@start_time, timestamp_column: 'tag_versions.created_at')
                                    .older_than_or_equal_to(@end_time, timestamp_column: 'tag_versions.created_at')
                                    .order('tag_versions.created_at ASC').each do |delta_performance_audit|
        @chart_data_for_provided_metric[:data] << [delta_performance_audit.audit.tag_version.created_at, delta_performance_audit[@metric_key]]
      end
    end

    def add_all_audits_from_within_timestamps
      AverageDeltaPerformanceAudit.includes(audit: :tag_version)
                                    .where(audits: { tag_id: @tag.id, throttled: false })
                                    .more_recent_than_or_equal_to(@start_time, timestamp_column: 'audits.created_at')
                                    .older_than_or_equal_to(@end_time, timestamp_column: 'audits.created_at')
                                    .order('audits.created_at ASC').each do |delta_performance_audit|
        @chart_data_for_provided_metric[:data] << [delta_performance_audit.audit.created_at, delta_performance_audit[@metric_key]]
      end
    end

    def add_starting_timestamps_if_necessary
      unless @tag.first_version.nil? || @tag.first_version.created_at > @start_time || @chart_data_for_provided_metric[:data].empty?
        @chart_data_for_provided_metric[:data] << [@start_time, @chart_data_for_provided_metric[:data].last[1]]
      end
    end
  end
end