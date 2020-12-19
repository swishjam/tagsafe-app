class ChartsController < ApplicationController
  def script_subscribers
    domain = Domain.find(params[:domain_id])
    metric = params[:metric] || 'DOMComplete'
    if params[:script_subscriber_ids]
      script_subscriber_ids = params[:script_subscriber_ids].is_a?(Array) ? params[:script_subscriber_ids] : JSON.parse(params[:script_subscriber_ids])
      chart_data_getter = ChartHelper::ScriptSubscribersData.new(script_subscriber_ids)
      render json: chart_data_getter.get_metric_data!(metric)
    else
      render json: []
    end
  end

  def script_subscriber
    script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(script_subscriber, raise_error: true)
    metric_keys = JSON.parse(params[:metric_keys] || "[\"DOMComplete\"]")
    chart_type = params[:chart_type] || 'impact'
    chart_data_getter = ChartHelper::ScriptSubscriberData.new(script_subscriber, chart_type, metric_keys)
    data = chart_data_getter.get_metric_data!
    render json: data
  end
end