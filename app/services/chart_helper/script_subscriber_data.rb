module ChartHelper
  class ScriptSubscriberData
    def initialize(script_subscriber:, start_time: 24.hours.ago, end_time: 5.minutes.from_now, metric_keys:)
      @script_subscriber = script_subscriber
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

    def add_first_timestamp_to_chart_data
      chart_data.each do |metric_data|
        metric_data[:data] << [
          @start_time, 
          @script_subscriber.audits_chart_data.just_before(@start_time)[metric_data[:name].gsub(' ', '_').to_sym]
        ]
      end
    end

    def chart_data
      @chart_data ||= @metric_keys.map do |metric|
        {
          name: metric.to_s.gsub('_', ' '),        
          data: script_subscribers_primary_delta_performance_audits.pluck('script_changes.created_at', metric)
        }
      end
    end

    def script_subscribers_primary_delta_performance_audits
      @performance_audits ||= DeltaPerformanceAudit.includes(audit: :script_change).where(audits: { script_subscriber_id: @script_subscriber.id, primary: true })
    end
  end
end