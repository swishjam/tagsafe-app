module Charts
  class TagsController < LoggedInController
    def index
      metric_key = (params[:metric_key] || 'tagsafe_score').to_sym
      time_range = (params[:time_range] || "24_hours").to_sym
      if params[:tag_ids]
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : JSON.parse(params[:tag_ids])
        tags = current_container.tags.where(id: tag_ids)
        include_metric_select = params[:include_metric_select] == 'true'
        chart_data_getter = ChartHelper::TagsData.new(
          tags: tags, 
          time_range: time_range,
          metric_key: metric_key
        )
        render turbo_stream: turbo_stream.replace(
          "#{current_container.uid}_container_tags_chart",
          partial: 'charts/tags/index',
          locals: { 
            chart_data: chart_data_getter.chart_data,
            tag_ids: tag_ids, 
            include_metric_select: include_metric_select,
            container: current_container, 
            metric_key: metric_key,
            time_range: time_range
          }
        )
      else
        render turbo_stream: turbo_stream.replace(
          "#{current_container.uid}_container_tags_chart",
          partial: 'charts/tags/index',
          locals: { 
            chart_data: [], 
            tag_ids: [],
            metric_key: metric_key,
            include_metric_select: include_metric_select,
            container: current_container,
            time_range: time_range
          }
        )
      end
    end
  
    def show
      time_range = (params[:time_range] || "24_hours").to_sym
      tag = current_container.tags.find_by(uid: params[:uid])
      chart_metric = (params[:chart_metric] || 'tagsafe_score').to_sym
      chart_data_getter = ChartHelper::TagsData.new(
        tags: [tag], 
        time_range: time_range,
        metric_key: chart_metric,
        use_metric_key_as_plot_name: true
      )
      render turbo_stream: turbo_stream.replace(
        "#{tag.uid}_tag_chart",
        partial: 'charts/tags/show',
        locals: { 
          chart_data: chart_data_getter.chart_data, 
          tag: tag, 
          container: current_container,
          chart_metric: chart_metric, 
          display_metric: chart_metric.to_s.gsub('delta', '').strip.split('_').map(&:capitalize).join(' '),
          time_range: time_range,
          hide_time_range_selector: params[:hide_time_range_selector],
          hide_chart_titles: params[:hide_chart_titles]
        }
      )
    end
  end
end