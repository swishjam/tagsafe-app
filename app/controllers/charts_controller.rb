class ChartsController < ApplicationController
  def script_subscribers
    domain = Domain.find(params[:domain_id])
    metric = params[:metric] || 'psi'
    script_subscriber_ids = params[:script_subscriber_ids].is_a?(Array) ? params[:script_subscriber_ids] : JSON.parse(params[:script_subscriber_ids])
    script_subscribers = ScriptSubscriber.where(id: script_subscriber_ids)
    chart_data_getter = ChartHelper::ScriptSubscribersData.new(script_subscribers)
    if metric == 'psi'
      render json: chart_data_getter.get_psi_data!
    else
      render json: chart_data_getter.get_metric_data!(metric)
    end
  end

  def script_subscriber
    script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(script_subscriber, raise_error: true)
    metric_keys = JSON.parse(params[:metric_keys] || "[\"psi\"]")
    chart_data_getter = ChartHelper::ScriptSubscriberData.new(script_subscriber)
    data = chart_data_getter.get_metric_data_by_keys!(metric_keys)
    render json: data
  end
end