class TagVersionsController < LoggedInController
  skip_before_action :authorize!, only: :content
  protect_from_forgery except: :content

  def show
    @tag_version = TagVersion.find(params[:id])
    permitted_to_view?(@tag_version)
    @previous_tag_version = @tag_version.previous_version
    @tag = @tag_version.tag
    @hide_navigation = true

    diff = Diffy::SplitDiff.new(
      @previous_tag_version&.content&.force_encoding('UTF-8'), 
      @tag_version.content.force_encoding('UTF-8'), 
      format: :html, 
      include_plus_and_minus_in_html: true
      # include_diff_info: true
    )

    @git_diff_tag_version = diff.right.html_safe
    @git_diff_previous_tag_version = diff.left.html_safe
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: "#{@tag_version.created_at.formatted} Tag Change", active: true}
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
end