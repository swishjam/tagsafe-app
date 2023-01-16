class ChangeRequestsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Change Requests')
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests' },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end

  def show
    @tag_version = current_container.tag_versions.includes(tag: :current_live_tag_version).find_by(uid: params[:tag_version_uid])
    @tag_version_to_compare_with = @tag_version.change_request_decisioned? ? @tag_version.live_tag_version_at_time_of_decision : @tag_version.tag.current_live_tag_version
    render_breadcrumbs(
      { url: change_requests_path, text: 'Change Requests' },
      { text: "#{@tag_version.tag_version_identifier} Change Request"}
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: change_requests_path, text: 'Change Requests', active: true },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end

  def decide
    tag_version = current_container.tag_versions.includes(tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
    if params[:decision] == 'approved'
      tag_version.approve_change_request(current_container_user)
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_change_request",
        partial: 'change_requests/show',
        locals: { 
          tag_version: tag_version,
          tag_version_to_compare_with: tag_version.tag.current_live_tag_version,
        }
      )
    elsif params[:decision] == 'denied'
      tag_version.deny_change_request(current_container_user)
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_change_request",
        partial: 'change_requests/show',
        locals: { 
          tag_version: tag_version,
          tag_version_to_compare_with: tag_version.tag.current_live_tag_version,
        }
      )
    else
      raise "Unrecognized decision: #{params[:decision]}"
    end
  end

  def list
    if params[:status] == 'closed'
      render turbo_stream: turbo_stream.replace(
        "#{current_container.uid}_change_requests",
        partial: 'change_requests/list',
        locals: { 
          container: current_container,
          status: 'closed',
          closed_change_requests: current_container.tag_versions.change_request_decided.includes(:tag),
        }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "#{current_container.uid}_change_requests",
        partial: 'change_requests/list',
        locals: { 
          container: current_container,
          status: 'open',
          tags_with_open_change_requests: current_container.tags.open_change_requests,
        }
      )
    end
  end

  def details
    tag_version = current_container.tag_versions.includes(:primary_audit, tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
    tag_version_to_compare_with = tag_version.change_request_decisioned? ? tag_version.live_tag_version_at_time_of_decision : tag_version.tag.current_live_tag_version
    render turbo_stream: turbo_stream.replace(
      "#{tag_version.uid}_change_request_details",
      partial: 'change_requests/details',
      locals: {
        tag_version: tag_version,
        tag_version_to_compare_with: tag_version_to_compare_with,
        container: current_container,
      }
    )
  end

  def git_diff
    tag_version = current_container.tag_versions.includes(tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
    tag_version_to_compare_with = tag_version.change_request_decisioned? ? tag_version.live_tag_version_at_time_of_decision : tag_version.tag.current_live_tag_version
    diff_analyzer = DiffAnalyzer.new(
      new_content: tag_version.content(formatted: true),
      previous_content: tag_version_to_compare_with&.content(formatted: true),
      num_lines_of_context: params[:num_lines_of_context] || 7,
      include_diff_info: true
    )
    render turbo_stream: turbo_stream.replace(
      "#{tag_version.uid}_git_diff_change_request",
      partial: 'change_requests/git_diff',
      locals: { 
        tag_version: tag_version,
        tag_version_to_compare_with: tag_version_to_compare_with,
        deletions_html: diff_analyzer.html_split_diff_deletions.html_safe,
        additions_html: diff_analyzer.html_split_diff_additions.html_safe,
      }
    )
  end
end