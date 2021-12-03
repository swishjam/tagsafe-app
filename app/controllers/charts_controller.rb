class ChartsController < ApplicationController
  def tags
    # domain = Domain.find(params[:domain_id])
    @displayed_metric = params[:metric_type] || :tagsafe_score
    if params[:tag_ids]
      tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
      tags = current_domain.tags.where(id: tag_ids)
      @start_time = params[:start_time].to_datetime
      @end_time = params[:end_time].to_datetime
      chart_data_getter = ChartHelper::TagsData.new(
        tags: tags, 
        start_time: @start_time,
        end_time: @end_time,
        metric_key: @displayed_metric
      )
      @include_metric_select = params[:include_metric_selector] == 'true'
      @chart_data = chart_data_getter.chart_data
    else
      @chart_data = []
    end
  end

  def tag
    @start_time = params[:start_time].to_datetime
    @end_time = params[:end_time].to_datetime
    @tag = current_domain.tags.find(params[:tag_id])
    @chart_metric = (params[:chart_metric] || 'tagsafe_score').to_sym
    chart_data_getter = ChartHelper::TagData.new(
      tag: @tag, 
      metric: @chart_metric,
      start_time: @start_time,
      end_time: @end_time
    )
    @chart_data = chart_data_getter.chart_data
  end

  def tag_uptime
    @start_time = params[:start_time].to_datetime
    @end_time = params[:end_time].to_datetime
    tags = Tag.where(id: params[:tag_ids])
    chart_data_getter = ChartHelper::TagUptimeData.new(tags, start_time: @start_time, end_time: @end_time)
    @chart_data = chart_data_getter.chart_data
  end

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end
end