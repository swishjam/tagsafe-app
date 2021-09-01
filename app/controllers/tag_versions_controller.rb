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

  def run_audit
    tag_version = TagVersion.find(params[:id])
    permitted_to_view?(tag_version, raise_error: true)
    tag_version.run_audit!(ExecutionReason.MANUAL)
    display_toast_message("Performing audit on #{tag_version.tag.try_friendly_name}")
    redirect_to request.referrer
  end

  def js
    tag_version = TagVersion.find(params[:id])
    render plain: tag_version.content
  end
end