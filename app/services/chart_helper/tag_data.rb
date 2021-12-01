module ChartHelper
  class TagData
    def initialize(tag:, start_time:, end_time:, metric:)
      @tag = tag
      @metric = metric
      @start_time = start_time
      @end_time = end_time
      add_current_timestamp_to_chart_data
    end
    
    def chart_data
      @chart_data ||= [{
        name: @metric.to_s.gsub('_', ' '),
        data: tags_primary_delta_performance_audits.pluck('tag_versions.created_at', @metric)
      }]
    end

    private

    def add_current_timestamp_to_chart_data
      chart_data.each do |metric_data|
        unless metric_data[:data].empty?
          metric_data[:data] << [Time.now, metric_data[:data][0][1]]
          # metric_data[:data] << [Time.now, metric_data[:data][metric_data[:data].length-1][1]]
        end
      end
    end

    def tags_primary_delta_performance_audits
      @performance_audits ||= DeltaPerformanceAudit.includes(audit: :tag_version)
                                                    .where(audits: { tag_id: @tag.id, primary: true, throttled: false })
                                                    .more_recent_than_or_equal_to(@start_time, timestamp_column: 'tag_versions.created_at')
                                                    .older_than_or_equal_to(@end_time, timestamp_column: 'tag_versions.created_at')
                                                    .order('tag_versions.created_at ASC')
    end
  end
end