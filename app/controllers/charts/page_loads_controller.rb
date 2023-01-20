module Charts
  class PageLoadsController < LoggedInController
    def index
      page_url = @container.page_urls.find_by(uid: params[:page_url_uid])
      # page_load_performance_metric_types = params[:page_load_performance_metric_types] || %w[DomCompletePerformanceMetric]
      page_load_performance_metric_types = params[:page_load_performance_metric_types] || PageLoadPerformanceMetric::TYPES
      time_range = params[:time_range] || :'24_hours'
      chart_helper = ChartHelper::PageLoadsData.new(
        page_url: page_url, 
        page_load_performance_metric_types: page_load_performance_metric_types,
        time_range: time_range
      )
      render turbo_stream: turbo_stream.replace(
          "#{@container.uid}_page_loads_chart",
          partial: 'charts/page_loads/index',
          locals: { 
            container: @container,
            chart_data: chart_helper.chart_data(include_performance_metrics: true, include_tagsafe_optimizations: false),
            tagsafe_optimizations_chart_data: chart_helper.chart_data(include_performance_metrics: false, include_tagsafe_optimizations: true),
            page_url: page_url,
            time_range: time_range,
            page_load_performance_metric_types: page_load_performance_metric_types,
            page_load_performance_metric_names: page_load_performance_metric_types.collect{ |type| type.constantize.friendly_name }
          }
        )
    end
  end
end