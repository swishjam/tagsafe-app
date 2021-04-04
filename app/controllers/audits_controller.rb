class AuditsController < LoggedInController
  def index
    @tag = Tag.find(params[:tag_id])
    permitted_to_view?(@tag)
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audits = @tag_version.audits.most_recent_first
    @primary_audit = @tag_version.primary_audit
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: "#{@tag_version.created_at.formatted_short} Audits", active: true }
    )
  end

  def show
    @tag = Tag.find(params[:tag_id])
    permitted_to_view?(@tag)
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = Audit.find(params[:id])
    @previous_audit = @tag_version.previous_version&.primary_audit
    @count_of_audits_for_tag_version = @tag_version.audits.count
    @metric_types = PerformanceAuditMetricType.all
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.created_at.formatted_short} Change Audits" },
      { text: "#{@audit.created_at.formatted_short} Audit", active: true }
    )
  end

  def make_primary
    audit = Audit.find(params[:id])
    permitted_to_view?(audit)
    audit.make_primary!
    flash[:banner_message] = "Successfully updated primary audit."
    redirect_to request.referrer
  end
end