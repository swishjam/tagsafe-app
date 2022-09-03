class TagVersionsController < LoggedInController
  protect_from_forgery except: :content

  def git_diff
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
    @tag_version = @tag.tag_versions.find_by(uid: params[:uid])

    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: @tag_version.sha, active: true}
    )
  end

  def index
    @tag_versions = TagVersion.where(tag_id: current_domain.tags)
                                .most_recent_first
                                .page(params[:page] || 1).per(params[:per_page || 10])
    @number_of_tags = current_domain.tags.release_monitoring_enabled.count
    render_breadcrumbs({ text: 'Releases', active: true })
  end

  def audit_redirect
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    tag_version = tag.tag_versions.find_by(uid: params[:uid])
    audit_execution_reason = params[:execution_reason_uid] ? ExecutionReason.find_by(uid: params[:execution_reason_uid]) : ExecutionReason.NEW_RELEASE
    audit = tag_version.audits.find_by(execution_reason: audit_execution_reason)
    if audit
      redirect_to tag_audit_path(tag, audit)
    else
      redirect_to tag_path(tag)
    end
  end

  def js
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    tag_version = tag.tag_versions.find_by(uid: params[:uid])
    render plain: tag_version.content
  end

  def live_comparison
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
    @tag_version = @tag.tag_versions.find_by(uid: params[:uid])
  end
end