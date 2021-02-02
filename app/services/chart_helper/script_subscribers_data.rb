module ChartHelper
  class ScriptSubscribersData
    def initialize(script_subscribers:, start_time:, end_time:, metric_key:)
      @script_subscribers = script_subscribers
      @start_time = start_time
      @metric_key = metric_key
    end
    
    def get_metric_data!
      add_current_timestamp_to_chart_data
      chart_data
    end

    def add_current_timestamp_to_chart_data
      chart_data.each do |script_subscriber_data|
        unless script_subscriber_data[:data].empty?
          script_subscriber_data[:data] << [Time.now, script_subscriber_data[:data][script_subscriber_data[:data].length-1][1]]
        end
      end
    end

    def chart_data
      @chart_data ||= script_subscribers_primary_delta_performance_audits.map do |friendly_name, delta_performance_audits|
        {
          name: friendly_name,
          data: delta_performance_audits.collect{ |dpa| [dpa.audit.script_change.created_at, dpa[@metric_key]] }
        }
      end
    end

    def script_subscribers_primary_delta_performance_audits
      @performance_audits ||= DeltaPerformanceAudit.includes(audit: [:script_subscriber, :script_change])
                                                    .where(audits: { script_subscriber_id: @script_subscribers.collect(&:id), primary: true })
                                                    .group_by{ |dpa| dpa.audit.script_subscriber.try_friendly_name }
    end
  end
end