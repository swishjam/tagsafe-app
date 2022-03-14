class ChartsController < ApplicationController
  layout false

  def tags
    # domain = Domain.find(params[:domain_id])
    displayed_metric = params[:metric_type] || :tagsafe_score
    start_time = (params[:start_time] || 1.day.ago).to_datetime
    end_time = (params[:end_time] || Time.now).to_datetime
    if params[:tag_ids]
      tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
      tags = current_domain.tags.includes(:tag_preferences).where(id: tag_ids)
      include_metric_select = params[:include_metric_select] == 'true'
      chart_data_getter = ChartHelper::TagsData.new(
        tags: tags, 
        start_time: start_time,
        end_time: end_time,
        metric_key: displayed_metric
      )
      render turbo_stream: turbo_stream.replace(
        "#{current_domain.uid}_domain_tags_chart",
        partial: 'charts/tags',
        locals: { 
          chart_data: chart_data_getter.chart_data, 
          include_metric_select: params[:include_metric_select],
          domain: current_domain, 
          displayed_metric: displayed_metric,
          start_time: start_time,
          end_time: end_time 
        }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "#{current_domain.uid}_domain_tags_chart",
        partial: 'charts/tags',
        locals: { 
          chart_data: [], 
          displayed_metric: :tagsafe_score,
          include_metric_select: params[:include_metric_select],
          domain: current_domain,
          start_time: start_time,
          end_time: end_time 
        }
      )
    end
  end

  def tag
    start_time = (params[:start_time] || 1.day.ago).to_datetime
    end_time = (params[:end_time] || Time.now).to_datetime
    tag = current_domain.tags.find(params[:tag_id])
    chart_metric = (params[:chart_metric] || 'tagsafe_score').to_sym
    chart_data_getter = ChartHelper::TagData.new(
      tag: tag, 
      metric: chart_metric,
      start_time: start_time,
      end_time: end_time
    )
    render turbo_stream: turbo_stream.replace(
      "#{tag.uid}_tag_chart",
      partial: 'charts/tag',
      locals: { 
        chart_data: chart_data_getter.chart_data, 
        tag: tag, 
        chart_metric: chart_metric, 
        display_metric: chart_data_getter.tooltip_title,
        start_time: start_time, 
        end_time: end_time 
      }
    )
  end

  def tag_uptime
    @start_time = params[:start_time].to_datetime
    @end_time = params[:end_time].to_datetime
    tags = current_domain.tags.where(id: params[:tag_ids])
    chart_data_getter = ChartHelper::TagsUptimeData.new(tags, start_time: @start_time, end_time: @end_time)
    @chart_data = chart_data_getter.chart_data
  end

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end

  def admin_executed_lambda_functions
    render json: ChartHelper::AdminExecutedLambdaFunctionsData.new.chart_data
  end
end