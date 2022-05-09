class ChartsController < ApplicationController
  layout false

  # def tags
  #   displayed_metric = params[:metric_type] || :tagsafe_score
  #   time_range = (params[:time_range] || "24_hours").to_sym
  #   if params[:tag_ids]
  #     tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
  #     tags = current_domain.tags.includes(:tag_preferences).where(id: tag_ids)
  #     include_metric_select = params[:include_metric_select] == 'true'
  #     chart_data_getter = ChartHelper::TagsData.new(
  #       tags: tags, 
  #       time_range: time_range,
  #       metric_key: displayed_metric
  #     )
  #     render turbo_stream: turbo_stream.replace(
  #       "#{current_domain.uid}_domain_tags_chart",
  #       partial: 'charts/tags',
  #       locals: { 
  #         chart_data: chart_data_getter.chart_data,
  #         tag_ids: tag_ids, 
  #         include_metric_select: params[:include_metric_select],
  #         domain: current_domain, 
  #         displayed_metric: displayed_metric,
  #         time_range: time_range
  #         # start_time: start_time,
  #         # end_time: end_time 
  #       }
  #     )
  #   else
  #     render turbo_stream: turbo_stream.replace(
  #       "#{current_domain.uid}_domain_tags_chart",
  #       partial: 'charts/tags',
  #       locals: { 
  #         chart_data: [], 
  #         tag_ids: [],
  #         displayed_metric: :tagsafe_score,
  #         include_metric_select: params[:include_metric_select],
  #         domain: current_domain,
  #         time_range: time_range
  #         # start_time: start_time,
  #         # end_time: end_time 
  #       }
  #     )
  #   end
  # end

  # def tag
  #   time_range = (params[:time_range] || "24_hours").to_sym
  #   tag = current_domain.tags.find_by(uid: params[:tag_uid])
  #   chart_metric = (params[:chart_metric] || 'tagsafe_score').to_sym
  #   chart_data_getter = ChartHelper::TagsData.new(
  #     tags: [tag], 
  #     time_range: time_range,
  #     metric_key: chart_metric,
  #     use_metric_key_as_plot_name: true
  #   )
  #   render turbo_stream: turbo_stream.replace(
  #     "#{tag.uid}_tag_chart",
  #     partial: 'charts/tag',
  #     locals: { 
  #       chart_data: chart_data_getter.chart_data, 
  #       tag: tag, 
  #       domain: current_domain,
  #       chart_metric: chart_metric, 
  #       display_metric: chart_metric.to_s.gsub('delta', '').strip.split('_').map(&:capitalize).join(' '),
  #       time_range: time_range
  #     }
  #   )
  # end

  # def tag_uptime
  #   @start_time = params[:start_time].to_datetime
  #   @end_time = params[:end_time].to_datetime
  #   @tags = current_domain.tags.where(id: params[:tag_ids])
  #   @uptime_region = UptimeRegion.find_by(aws_name: params[:aws_region] || 'us-east-1')
  #   chart_data_getter = ChartHelper::TagsUptimeData.new(@tags, uptime_region: @uptime_region, start_time: @start_time, end_time: @end_time)
  #   @chart_data = chart_data_getter.chart_data
  # end

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end

  def admin_executed_step_functions
    render json: ChartHelper::AdminExecutedStepFunctionsData.new.chart_data
  end
end