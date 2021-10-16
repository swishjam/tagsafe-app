class TagVersionsController < LoggedInController
  skip_before_action :authorize!, only: :content
  protect_from_forgery except: :content
  hide_navigation_on :diff

  def diff
    @tag_version = TagVersion.find(params[:id])
    permitted_to_view?(@tag_version)
    @tag = @tag_version.tag

    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: @tag_version.sha, active: true}
      # { text: "#{@tag_version.created_at.formatted} Tag Change", active: true}
    )
  end

  def index
    @tag_versions = TagVersion.where(tag_id: current_domain.tags.is_third_party_tag)
                                .most_recent_first
                                .page(params[:page] || 1).per(params[:per_page || 10])
    # @audits = Audit.joins(:tag, :tag_version)
    #                 .where(primary: true, execution_reason: ExecutionReason.TAG_CHANGE, tag: current_domain.tags)
    #                 .most_recent_first
    #                 .page(params[:page] || 1).per(params[:per_page] || 10)
    @number_of_tags = current_domain.tags.is_third_party_tag.monitor_changes.count
  end

  def begin_audit
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:id])
    render turbo_stream: turbo_stream.replace(
      'server_loadable_modal_content',
      partial: 'begin_audit',
      locals: { tag: tag, tag_version: tag_version }
    )
  end

  def run_audit
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:id])
    permitted_to_view?(tag_version, raise_error: true)
    UrlToAudit.where(id: params[:urls_to_audit]).each do |url_to_audit|
      # tag_version.perform_audit_later(execution_reason: ExecutionReason.MANUAL, url_to_audit: url_to_audit, enable_tracing: params[:enable_tracing] == 'true')
    end
    msg = "Performing #{params[:urls_to_audit].count} audit(s) on #{tag_version.tag.try_friendly_name}"
    # current_user.broadcast_notification(msg, image: tag_version.image_url)
    render turbo_stream: turbo_stream.replace(
      'server_loadable_modal_content',
      partial: 'begin_audit',
      locals: { tag: tag, tag_version: tag_version, display_message: msg }
    )
  end

  def js
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:id])
    render plain: tag_version.content
  end

  def tagsafe_instrumented_js
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:id])
    render plain: tag_version.tagsafe_instrumented_content
  end
end