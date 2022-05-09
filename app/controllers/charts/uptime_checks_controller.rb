module Charts
  class UptimeChecksController < LoggedInController
    def index
      time_range = (params[:time_range] || '24_hours').to_sym
      tags = current_domain.tags.where(id: params[:tag_ids])
      uptime_region = UptimeRegion.find_by(aws_name: params[:aws_region] || 'us-east-1')
      chart_data_getter = ChartHelper::TagsUptimeData.new(tags, uptime_regions: [uptime_region], time_range: time_range)
      render turbo_stream: turbo_stream.replace(
        "domain_#{current_domain.uid}_tags_uptime",
        partial: 'charts/uptime_checks/index',
        locals: {
          domain: current_domain,
          chart_data: chart_data_getter.chart_data,
          time_range: time_range,
          selected_uptime_region: uptime_region,
          tag_ids: params[:tag_ids]
        }
      )
    end

    def show
      time_range = (params[:time_range] || '24_hours').to_sym
      tag = current_domain.tags.find_by(uid: params[:uid])
      uptime_regions = UptimeRegion.where(aws_name: params[:aws_regions] || ['us-east-1'])
      chart_data_getter = ChartHelper::TagsUptimeData.new([tag], uptime_regions: uptime_regions, time_range: time_range, use_uptime_region_as_plot_name: true)
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_uptime_chart",
        partial: 'charts/uptime_checks/show',
        locals: {
          domain: current_domain,
          tag: tag,
          chart_data: chart_data_getter.chart_data,
          time_range: time_range,
          selected_uptime_regions: uptime_regions,
          chart_type: params[:chart_type] || 'line'
        }
      )
    end
  end
end