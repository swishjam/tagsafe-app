module Charts
  class TagChecksController < LoggedInController
    def index
      time_range = (params[:time_range] || '24_hours').to_sym
      tags = current_domain.tags.where(id: params[:tag_ids])
      tag_check_region = TagCheckRegion.find_by(aws_name: params[:aws_region] || 'us-east-1')
      chart_data_getter = ChartHelper::TagsUptimeData.new(tags, tag_check_regions: [tag_check_region], time_range: time_range)
      render turbo_stream: turbo_stream.replace(
        "domain_#{current_domain.uid}_tags_uptime",
        partial: 'charts/tag_checks/index',
        locals: {
          domain: current_domain,
          chart_data: chart_data_getter.chart_data,
          time_range: time_range,
          selected_tag_check_region: tag_check_region,
          tag_ids: params[:tag_ids]
        }
      )
    end

    def show
      time_range = (params[:time_range] || '24_hours').to_sym
      tag = current_domain.tags.find_by(uid: params[:uid])
      tag_check_regions = TagCheckRegion.where(aws_name: params[:aws_regions] || ['us-east-1'])
      chart_data_getter = ChartHelper::TagsUptimeData.new([tag], tag_check_regions: tag_check_regions, time_range: time_range, use_tag_check_region_as_plot_name: true)
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_uptime_chart",
        partial: 'charts/tag_checks/show',
        locals: {
          domain: current_domain,
          tag: tag,
          chart_data: chart_data_getter.chart_data,
          time_range: time_range,
          selected_tag_check_regions: tag_check_regions,
          chart_type: params[:chart_type] || 'line'
        }
      )
    end
  end
end