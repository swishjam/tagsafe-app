module ChartHelper
  class TagsData
    def initialize(tags:, start_time:, end_time:, metric_key:)
      @tags = tags
      @start_time = start_time
      @end_time = end_time
      @metric_key = metric_key
      add_current_timestamp_to_chart_data
    end
  
    def chart_data
      @chart_data ||= tags_primary_delta_performance_audits.map do |friendly_name, delta_performance_audits|
        {
          name: friendly_name,
          data: delta_performance_audits.collect{ |dpa| [dpa.audit.tag_version.created_at, dpa[@metric_key]] }
        }
      end
    end

    private

    def add_current_timestamp_to_chart_data
      chart_data.each do |tag_data|
        unless tag_data[:data].empty?
          tag_data[:data] << [DateTime.now, tag_data[:data][0][1]]
          # tag_data[:data] << [DateTime.now, tag_data[:data][tag_data[:data].length-1][1]]
        end
      end
    end

    def tags_primary_delta_performance_audits
      @performance_audits ||= DeltaPerformanceAudit.includes(audit: [:tag, :tag_version])
                                                    .where(audits: { tag_id: @tags.collect(&:id), primary: true })
                                                    .more_recent_than_or_equal_to(@start_time, timestamp_column: 'tag_versions.created_at')
                                                    .older_than_or_equal_to(@end_time, timestamp_column: 'tag_versions.created_at')
                                                    .order('tag_versions.created_at ASC')
                                                    .group_by{ |dpa| dpa.audit.tag.try_friendly_name }
                                                    # .where("audits.tag_id IN ?", @tags.collect(&:id))

    end
  end
end