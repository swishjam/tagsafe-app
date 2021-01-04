module ChartHelper
  class ScriptSubscribersData
    def initialize(script_subscribers)
      @script_subscribers = script_subscribers
    end

    def get_metric_data!(metric_key)
      chart_data = []
      @script_subscribers.each do |script_subscriber|
        script_change_data = []
        script_subscriber.script.script_changes.most_recent_last.each do |script_change|
          primary_audit = script_subscriber.primary_audit_by_script_change(script_change)
          unless primary_audit.nil?
            script_change_data << [script_change.created_at, primary_audit.delta_performance_audit.performance_audit_metrics.by_key(metric_key).first.result]
          end
        end
        script_change_data << [Time.now, script_change_data.first[1]] unless script_change_data.empty?
        chart_data << { name: script_subscriber.try_friendly_name, data: script_change_data }	
      end
      chart_data
    end

    def data_points_for_script_subscribers_chart_data(chart_datas, metric_key)
      data_points = chart_datas.map{ |data| [data.timestamp, data.performance_audit_metric_result(metric_key)] }
      data_points << [Time.now, chart_datas.first.performance_audit_metric_result(metric_key)]
    end
  end
end