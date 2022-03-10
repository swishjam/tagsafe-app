module ChartHelper
  class TagsData
    def initialize(tags:, start_time:, end_time:, metric_key:)
      @tags = tags
      @start_time = start_time
      @end_time = end_time
      @metric_key = metric_key
      @chart_data = {}
    end
  
    def chart_data
      format_chart_data!
    end

    private

    def format_chart_data!
      add_current_timestamp_to_chart_data
      add_tag_versions_from_within_timeframes_primary_audits
      add_starting_timestamps_if_necessary
      @chart_data.values
    end

    def add_current_timestamp_to_chart_data
      @tags.map do |tag|
        # TODO: need to take into account when the two most recent tag versions dont have a primary audit, there should be a cleaner query for this.
        current_primary_audit = tag.current_version&.primary_audit || tag.current_version&.previous_version&.primary_audit
        unless current_primary_audit.nil?
          @chart_data[tag] = { name: tag.try_friendly_name, data: [[DateTime.now, current_primary_audit.average_delta_performance_audit[@metric_key]]] }
        end
      end
    end

    def add_tag_versions_from_within_timeframes_primary_audits
      AverageDeltaPerformanceAudit.includes(audit: [:tag, :tag_version])
                                    .where(audits: { tag_id: @tags.collect(&:id), primary: true })
                                    .more_recent_than_or_equal_to(@start_time, timestamp_column: 'tag_versions.created_at')
                                    .older_than_or_equal_to(@end_time, timestamp_column: 'tag_versions.created_at')
                                    .order('tag_versions.created_at ASC')
                                    .group_by{ |dpa| dpa.audit.tag }.each do |tag, delta_performance_audits|
        chart_data_for_tag = delta_performance_audits.collect{ |dpa| [dpa.audit.tag_version.created_at, dpa[@metric_key]] }
        @chart_data[tag] = @chart_data[tag] || { name: tag.try_friendly_name, data: [] }
        @chart_data[tag][:data].concat(chart_data_for_tag)
      end
    end

    def add_starting_timestamps_if_necessary
      @chart_data.each do |tag, chart_data_hash|
        unless tag.first_version.created_at > @start_time
          chart_data_hash[:data] << [@start_time, chart_data_hash[:data].last[1]]
        end
      end
    end
  end
end