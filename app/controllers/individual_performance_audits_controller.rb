class IndividualPerformanceAuditsController < LoggedInController
  def index
    @tag = Tag.find(params[:tag_id])
    permitted_to_view?(@tag)
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = Audit.includes(:performance_audits).find(params[:audit_id])

    @average_delta_audit = @audit.average_delta_performance_audit
    @median_delta_audit = @audit.median_delta_performance_audit
    @individual_delta_audits = @audit.individual_delta_performance_audits.includes(:performance_audit_with_tag, :performance_audit_without_tag)
    @failed_individual_audits = @audit.individual_performance_audits.failed
    @pending_individual_audits = @audit.individual_performance_audits.pending
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.sha} Audits" },
      { url: performance_audit_tag_tag_version_audit_path(@tag, @tag_version, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "Individual Performance Audits", active: true }
    )
  end
end