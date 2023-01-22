module Charts
  class TagsController < LoggedInController
    def index
      metric_key = (params[:metric_key] || 'tagsafe_score').to_sym
      time_range = (params[:time_range] || "24_hours").to_sym
      if params[:tag_ids]
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
        tags = @container.tags.where(id: tag_ids)
        include_metric_select = params[:include_metric_select] == 'true'
        chart_data_getter = ChartHelper::TagsData.new(
          tags: tags, 
          time_range: time_range,
          metric_key: metric_key
        )
        render turbo_stream: turbo_stream.replace(
          "#{@container.uid}_container_tags_chart",
          partial: 'charts/tags/index',
          locals: { 
            chart_data: chart_data_getter.chart_data,
            tag_ids: tag_ids, 
            include_metric_select: include_metric_select,
            container: @container, 
            metric_key: metric_key,
            time_range: time_range
          }
        )
      else
        render turbo_stream: turbo_stream.replace(
          "#{@container.uid}_container_tags_chart",
          partial: 'charts/tags/index',
          locals: { 
            chart_data: [], 
            tag_ids: [],
            metric_key: metric_key,
            include_metric_select: include_metric_select,
            container: @container,
            time_range: time_range
          }
        )
      end
    end
  
    def show
      tag = @container.tags.find_by(uid: params[:uid])
      time_range = (params[:time_range] || "24_hours").to_sym
      chart_helper = ChartHelper::TagData.new(tag: tag, time_range: time_range)
      chart_data = chart_helper.chart_data
      render turbo_stream: turbo_stream.replace(
        "#{tag.uid}_tag_chart",
        partial: 'charts/tags/show',
        locals: { 
          chart_data: chart_data, 
          tag: tag, 
          container: @container,
          time_range: time_range,
          start_datetime: (chart_helper.start_datetime.to_f * 1_000).floor,
          hide_time_range_selector: params[:hide_time_range_selector],
          hide_chart_titles: params[:hide_chart_titles],
          small_chart: params[:small_chart],
          graph_zone_options: chart_helper.graph_zone_data(depth: params[:small_chart] ? 100 : 300)
        }
      )
    end
  end
end