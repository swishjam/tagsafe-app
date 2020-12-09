module ChartHelper
  class ScriptSubscribersData
    def initialize(script_subscribers)
      @script_subscribers = script_subscribers
    end

    def get_metric_data!(metric_key)
      chart_data = []
      @script_subscribers.each do |script_subscriber|
        script_change_data = {}
        script_subscriber.script.script_changes.most_recent_last.each do |script_change|
          primary_audit = script_subscriber.primary_audit_by_script_change(script_change)
          unless primary_audit.nil?
            script_change_data[script_change.created_at] = primary_audit.delta_performance_audit.performance_audit_metrics.by_key(metric_key).first.result
          end
        end
        chart_data << { name: script_subscriber.try_friendly_name, data: script_change_data }
      end
      chart_data
    end
  end
end