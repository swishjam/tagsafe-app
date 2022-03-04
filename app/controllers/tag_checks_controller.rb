class TagChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @tags = current_domain.tags
                            .available_for_uptime
                            .order('content_changed_at DESC')
                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end

  def tag
    tag = current_domain.tags.find(params[:tag_id])
    start_time = params[:start_time] || 1.day.ago
    end_time = params[:end_time] || Time.now
    tag_checks = tag.tag_checks.where(created_at: start_time..end_time).most_recent_first
    chart_data = ChartHelper::TagUptimeData.new(tag_checks, start_time: start_time, end_time: end_time).chart_data
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_uptime",
      partial: 'tags/uptime_chart_and_list',
      locals: {
        tag: tag,
        paginated_tag_checks: tag_checks.page(params[:page] || 1).per(params[:per_page] || 50),
        chart_data: chart_data,
        start_time: start_time,
        end_time: end_time
      }
    )
  end
end