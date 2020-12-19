module ChartHelper
  class ScriptSubscribersData
    def initialize(script_subscriber_ids)
      @script_subscriber_ids = script_subscriber_ids
    end

    def get_metric_data!(metric_key)
      chart_data.group_by{ |data| data.audit.script_subscriber.try_friendly_name }.map do |script_subscriber_name, chart_datas|
        {
          name: script_subscriber_name,
          data: data_points_for_script_subscribers_chart_data(chart_datas, metric_key)
        }
      end
    end

    def data_points_for_script_subscribers_chart_data(chart_datas, metric_key)
      data_points = chart_datas.map{ |data| [data.timestamp, data.performance_audit_metric_result(metric_key)] }
      data_points << [Time.now, chart_datas.first.performance_audit_metric_result(metric_key)]
    end

    def chart_data
      @chart_data ||= ChartData.by_script_subscriber_id(@script_subscriber_ids).most_recent_first
    end
  end
end