class TagChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @tags = current_domain.tags
                            .available_for_uptime
                            .order('last_released_at DESC')
                            .page(params[:page] || 1).per(params[:per_page] || 9)
    render_breadcrumbs(text: 'Uptime', active: true)
  end

  def tag_chart
    tag = current_domain.tags.includes(:tag_check_regions).find(params[:tag_id])
    selected_tag_check_regions = TagCheckRegion.where(aws_name: params[:aws_region_names] || 'us-east-1')
    start_time = (params[:start_time] || 1.day.ago).to_datetime
    end_time = (params[:end_time] || Time.now).to_datetime
    chart_helper = ChartHelper::TagUptimeData.new(tag, tag_check_regions: selected_tag_check_regions, start_time: start_time, end_time: end_time)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_uptime_chart",
      partial: 'tags/uptime_chart',
      locals: {
        tag: tag,
        selected_tag_check_regions: selected_tag_check_regions,
        chart_data: chart_helper.chart_data,
        start_time: start_time,
        end_time: end_time
      }
    )
  end

  def tag_list
    tag = current_domain.tags.includes(:tag_check_regions).find(params[:tag_id])
    selected_tag_check_regions = TagCheckRegion.where(aws_name: params[:aws_region_names] || 'us-east-1')
    paginated_tag_checks = tag.tag_checks.includes(:tag_check_region)
                                          .measured_uptime
                                          .by_tag_check_region(selected_tag_check_regions)
                                          .most_recent_first(timestamp_column: 'tag_checks.created_at')
                                          .page(params[:page] || 1).per(params[:per_page] || 50)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_uptime_list",
      partial: 'tags/uptime_list',
      locals: {
        tag: tag,
        selected_tag_check_regions: selected_tag_check_regions,
        paginated_tag_checks: paginated_tag_checks
      }
    )
  end
end