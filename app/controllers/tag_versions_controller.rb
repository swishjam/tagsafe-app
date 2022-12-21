class TagVersionsController < LoggedInController
  protect_from_forgery except: :content
  before_action :find_tag

  def git_diff
    @tag_version = @tag.tag_versions.find_by!(uid: params[:uid])

    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: @tag_version.sha, active: true}
    )
  end

  def index
    @tag_versions = @tag.tag_versions
                          .most_recent_first
                          .page(params[:page] || 1)
                          .per(params[:per_page] || 10)
  end

  def update
    @tag_version = @tag.tag_versions.find_by(uid: params[:uid])
    raise "TODO"
  end

  def audit_redirect
    tag_version = @tag.tag_versions.find_by(uid: params[:uid])
    audit_execution_reason = params[:execution_reason_uid] ? ExecutionReason.find_by(uid: params[:execution_reason_uid]) : ExecutionReason.NEW_RELEASE
    audit = tag_version.audits.find_by(execution_reason: audit_execution_reason)
    if audit
      redirect_to tag_audit_path(@tag, audit)
    else
      redirect_to tag_path(@tag)
    end
  end

  def js
    tag_version = @tag.tag_versions.find_by(uid: params[:uid])
    render plain: tag_version.content
  end

  private

  def find_tag
    @tag = current_container.tags.find_by!(uid: params[:tag_uid])
  end
end