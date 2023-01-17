class TagVersionsController < LoggedInController
  protect_from_forgery except: :content
  before_action :find_tag

  def git_diff
    @tag_version = @tag.tag_versions.find_by!(uid: params[:uid])

    render_breadcrumbs(
      { url: container_tag_snippets_path(@container), text: "Monitor Center" },
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

  def promote
    tag_version = @tag.tag_versions.find_by!(uid: params[:uid])
    is_rolling_back = tag_version.older_than_current_live_version?
    is_promoting = !is_rolling_back
    stream_modal(locals: { 
      tag: @tag, 
      tag_version: tag_version,
      is_rolling_back: is_rolling_back,
      is_promoting: !is_rolling_back,
      num_releases_from_live_version: tag_version.num_releases_from_live_version
    })
  end

  def set_as_live_tag_version
    tag_version = @tag.tag_versions.find_by!(uid: params[:uid])
    did_roll_back = tag_version.older_than_current_live_version?
    @tag.set_current_live_tag_version_and_publish_instrumentation(tag_version)
    stream_modal(
      partial: 'modals/promote',
      locals: { 
        tag: @tag, 
        tag_version: tag_version, 
        did_roll_back: did_roll_back,
        did_promote: !did_roll_back,
        completed: true
      }
    )
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
    @tag = @container.tags.find_by!(uid: params[:tag_uid])
  end
end