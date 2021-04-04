class ChartsController < ApplicationController
  def tags
    domain = Domain.find(params[:domain_id])
    metric = params[:metric_type] || :tagsafe_score
    if params[:tag_ids]
      tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
      tags = current_domain.tags.where(id: tag_ids)
      chart_data_getter = ChartHelper::TagsData.new(
        tags: tags, 
        start_time: params[:start_time] || 24.hours.ago,
        end_time: params[:end_time] || Time.now,
        metric_key: metric
      )
      render json: chart_data_getter.get_metric_data!
    else
      render json: []
    end
  end

  def tag
    tag = Tag.find(params[:tag_id])
    permitted_to_view?(tag, raise_error: true)
    metric_keys = JSON.parse(params[:metric_keys] || "[\"tagsafe_score\"]")
    chart_data_getter = ChartHelper::TagData.new(
      tag: tag, 
      metric_keys: metric_keys,
      start_time: params[:start_time] || 24.hours.ago,
      end_time: params[:end_time] || Time.now
    )
    data = chart_data_getter.get_metric_data!
    render json: data
  end

  def tag_uptime
    tags = Tag.where(id: params[:tag_ids]).more_recent_than(params[:days_ago].to_i.day.ago)
    chart_data_getter = ChartHelper::TagUptimeData.new(tags)
    render json: chart_data_getter.get_response_time_data!
  end

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end
end