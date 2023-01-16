class ReleasesController < LoggedInController
  def all
    @tag_versions = current_container.tag_versions.not_first_version.most_recent_first.page(params[:page]).per(15)
    render_breadcrumbs(text: 'Releases')
    @navigation_items = [
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    ]
  end

  def index
    @tag = current_container.tags.find_by!(uid: params[:uid])
    @tag_versions = @tag.tag_versions.most_recent_first.page(params[:page]).per(15)
    render_breadcrumbs(
      { text: 'Monitor Center', url: root_path },
      { text: "#{@tag.try_friendly_name} releases" }
    )
  end

  def release_calendar
    @container_or_tag = params[:all_tags] ? current_container : current_container.tags.find_by!(uid: params[:tag_uid])
    range = Time.current.beginning_of_month.beginning_of_week.to_datetime..Time.current.end_of_month.to_datetime
    @first_tag_version_date = @container_or_tag.tag_versions.select(:created_at).most_recent_last(timestamp_column: :'tag_versions.created_at').limit(1).first&.created_at
    @release_count_by_day = @container_or_tag.tag_versions.not_first_version.group_by_day(:created_at, range: range).count
    @most_releases_in_a_day = @release_count_by_day.max_by{|k,v| v}[1]
  end
end
