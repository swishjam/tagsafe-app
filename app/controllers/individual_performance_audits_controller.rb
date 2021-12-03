class IndividualPerformanceAuditsController < LoggedInController
  def index
    @tag = Tag.find(params[:tag_id])
    permitted_to_view?(@tag)
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = Audit.includes(:individual_performance_audits_with_tag, :individual_performance_audits_without_tag)
                    .find(params[:audit_id])
    @audits_with_tag = @audit.individual_performance_audits_with_tag.order(tagsafe_score: :DESC)
    @audits_without_tag = @audit.individual_performance_audits_without_tag.order(tagsafe_score: :DESC)
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.sha} Audits" },
      { url: tag_tag_version_audit_path(@tag, @tag_version, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "Individual Performance Audits", active: true }
    )
  end
end