class ReleasesController < LoggedInController
  def all
    render_breadcrumbs(text: 'Releases')
  end

  def index
    @tag = current_domain.tags.find_by(uid: params[:uid])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path },
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Releases" }
    )
  end

  def release_chart
    domain_or_tag = params[:all_tags] ? current_domain : current_domain.tags.find_by(uid: params[:tag_uid])
    range = ((365.days.ago.beginning_of_week - 1.day).to_datetime..Time.current.beginning_of_day.to_datetime)
    num_releases_last_30_days = domain_or_tag.tag_versions.more_recent_than_or_equal_to(30.days.ago.beginning_of_day, timestamp_column: :'tag_versions.created_at').count
    first_tag_version_date = domain_or_tag.tag_versions.select(:created_at).most_recent_last(timestamp_column: :'tag_versions.created_at').limit(1).first.created_at
    release_count_by_day = domain_or_tag.tag_versions.group_by_day(:created_at, range: range).count
    most_releases_in_a_day = release_count_by_day.max_by{|k,v| v}[1]
    render turbo_stream: turbo_stream.replace(
      "#{domain_or_tag.uid}_release_chart",
      partial: 'releases/release_chart',
      locals: {
        num_releases_last_30_days: num_releases_last_30_days,
        first_tag_version_date: first_tag_version_date,
        release_count_by_day: release_count_by_day,
        most_releases_in_a_day: most_releases_in_a_day
      }
    )
  end

  def release_list
    start_date = params[:start_date].to_datetime
    end_date = params[:end_date].to_datetime
    domain_or_tag = params[:all_tags] ? current_domain : current_domain.tags.find_by(uid: params[:tag_uid])
    tag_versions_for_month = domain_or_tag.tag_versions
                                            .includes(:tag)
                                            .more_recent_than_or_equal_to(start_date, timestamp_column: :'tag_versions.created_at')
                                            .older_than_or_equal_to(end_date, timestamp_column: :'tag_versions.created_at')
                                            .most_recent_first(timestamp_column: :'tag_versions.created_at')
    most_changes_in_a_release_for_month = tag_versions_for_month.where.not(total_changes: nil).pluck(:total_changes).max
    render turbo_stream: turbo_stream.replace(
      "#{domain_or_tag.uid}_release_list_for_#{start_date.month}-#{start_date.year}_to_#{end_date.month}-#{end_date.year}",
      partial: 'releases/release_list',
      locals: {
        tag_versions_for_month: tag_versions_for_month,
        most_changes_in_a_release_for_month: most_changes_in_a_release_for_month,
        start_date: start_date,
        end_date: end_date,
        hide_tag_name: params[:hide_tag_name] == 'true'
      }
    )
  end
end