module ChartHelper
  class TagData
    def initialize(tag:, start_time: 24.hours.ago, end_time: 5.minutes.from_now, metric_keys:)
      @tag = tag
      @metric_keys = metric_keys
      @start_time = start_time
      @end_time = end_time
    end

    def get_metric_data!
      add_current_timestamp_to_chart_data
      chart_data
    end

    private

    def add_current_timestamp_to_chart_data
      chart_data.each do |metric_data|
        unless metric_data[:data].empty?
          metric_data[:data] << [Time.now, metric_data[:data][metric_data[:data].length-1][1]]
        end
      end
    end

    def chart_data
      @chart_data ||= @metric_keys.map do |metric|
        {
          name: metric.to_s.gsub('_', ' '),        
          data: tags_primary_delta_performance_audits.pluck('tag_versions.created_at', metric)
        }
      end
    end

    def tags_primary_delta_performance_audits
      @performance_audits ||= DeltaPerformanceAudit.includes(audit: :tag_version)
                              .where(audits: { tag_id: @tag.id, primary: true, throttled: false })
    end
  end
end