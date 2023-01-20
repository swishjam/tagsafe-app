class ChangeRequestsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Change Requests' }
    )
    render_default_navigation_items(:change_requests)
  end

  def show
    @tag_version = @container.tag_versions.includes(tag: :current_live_tag_version).find_by(uid: params[:tag_version_uid])
    @tag_version_to_compare_with = @tag_version.change_request_decisioned? ? @tag_version.live_tag_version_at_time_of_decision : @tag_version.tag.current_live_tag_version
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { text: "#{@tag_version.tag_version_identifier} Change Request"}
    )
    render_default_navigation_items(:change_requests)
  end

  def decide
    tag_version = @container.tag_versions.includes(tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
    if params[:decision] == 'approved'
      tag_version.approve_change_request(current_container_user)
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_change_request",
        partial: 'change_requests/show',
        locals: { 
          tag_version: tag_version,
          tag_version_to_compare_with: tag_version.tag.current_live_tag_version,
          container: @container,
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
          container: @container,
        }
      )
    else
      raise "Unrecognized decision: #{params[:decision]}"
    end
  end

  def list
    if params[:status] == 'closed'
      render turbo_stream: turbo_stream.replace(
        "#{@container.uid}_change_requests",
        partial: 'change_requests/list',
        locals: { 
          container: @container,
          status: 'closed',
          closed_change_requests: @container.tag_versions.change_request_decided.includes(:tag),
        }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "#{@container.uid}_change_requests",
        partial: 'change_requests/list',
        locals: { 
          container: @container,
          status: 'open',
          tags_with_open_change_requests: @container.tags.open_change_requests,
        }
      )
    end
  end

  def details
    tag_version = @container.tag_versions.includes(:primary_audit, tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
    tag_version_to_compare_with = tag_version.change_request_decisioned? ? tag_version.live_tag_version_at_time_of_decision : tag_version.tag.current_live_tag_version
    render turbo_stream: turbo_stream.replace(
      "#{tag_version.uid}_change_request_details",
      partial: 'change_requests/details',
      locals: {
        tag_version: tag_version,
        tag_version_to_compare_with: tag_version_to_compare_with,
        container: @container,
      }
    )
  end

  def git_diff
    tag_version = @container.tag_versions.includes(tag: :current_live_tag_version).find_by!(uid: params[:tag_version_uid])
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

  def count
    render turbo_stream: turbo_stream.replace(
      "#{@container.uid}_change_requests_count_indicator",
      partial: 'change_requests/count_indicator',
      locals: { 
        container_uid: @container.uid,
        open_change_requests_count: @container.tags.open_change_requests.count,
      }
    )
  end
end