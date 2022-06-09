class UptimeChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @tags = current_domain.tags.chartable
                                .order('last_released_at DESC')
                                .page(params[:page] || 1).per(params[:per_page] || 9)
    render_breadcrumbs(text: 'Uptime')
  end

  def domain_list
    render turbo_stream: turbo_stream.replace(
      "domain_#{current_domain.uid}_uptime_list",
      partial: 'uptime_checks/domain_list',
      locals: {
        tags: current_domain.tags.includes(:tag_preferences).page(params[:page] || 1).per(10),
        days_ago: params[:days_ago] || 7
      }
    )
  end

  def tag_list
    tag = current_domain.tags.includes(:uptime_regions).find_by(uid: params[:tag_uid])
    selected_uptime_regions = UptimeRegion.where(aws_name: params[:aws_region_names] || 'us-east-1')
    paginated_uptime_checks = tag.uptime_checks
                                    .includes(:uptime_region)
                                    .by_uptime_region(selected_uptime_regions)
                                    .most_recent_first(timestamp_column: 'uptime_checks.executed_at')
                                    .page(params[:page] || 1).per(params[:per_page] || 50)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_uptime_list",
      partial: 'tags/uptime_list',
      locals: {
        tag: tag,
        selected_uptime_regions: selected_uptime_regions,
        paginated_uptime_checks: paginated_uptime_checks
      }
    )
  end
end