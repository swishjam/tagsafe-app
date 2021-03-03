class ChartsController < ApplicationController
  def script_subscribers
    domain = Domain.find(params[:domain_id])
    metric = params[:metric_type] || :tagsafe_score
    if params[:script_subscriber_ids]
      script_subscriber_ids = params[:script_subscriber_ids].is_a?(Array) ? params[:script_subscriber_ids] : JSON.parse(params[:script_subscriber_ids])
      script_subscribers = current_domain.script_subscriptions.where(id: script_subscriber_ids)
      chart_data_getter = ChartHelper::ScriptSubscribersData.new(
        script_subscribers: script_subscribers, 
        start_time: params[:start_time] || 24.hours.ago,
        end_time: params[:end_time] || Time.now,
        metric_key: metric
      )
      render json: chart_data_getter.get_metric_data!
    else
      render json: []
    end
  end

  def script_subscriber
    script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(script_subscriber, raise_error: true)
    metric_keys = JSON.parse(params[:metric_keys] || "[\"tagsafe_score\"]")
    chart_data_getter = ChartHelper::ScriptSubscriberData.new(
      script_subscriber: script_subscriber, 
      metric_keys: metric_keys,
      start_time: params[:start_time] || 24.hours.ago,
      end_time: params[:end_time] || Time.now
    )
    data = chart_data_getter.get_metric_data!
    render json: data
  end

  def tag_uptime
    script_subscribers = ScriptSubscriber.where(id: params[:script_subscriber_ids]).more_recent_than(params[:days_ago].to_i.day.ago)
    chart_data_getter = ChartHelper::TagUptimeData.new(script_subscribers)
    render json: chart_data_getter.get_response_time_data!
  end

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end
end