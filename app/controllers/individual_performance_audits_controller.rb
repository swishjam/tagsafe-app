class IndividualPerformanceAuditsController < LoggedInController
  def index
    @tag = current_domain.tags.find(params[:tag_id])
    # permitted_to_view?(@tag)
    # @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = @tag.audits.includes(:performance_audits).find(params[:audit_id])

    @average_delta_audit = @audit.average_delta_performance_audit
    @median_delta_audit = @audit.median_delta_performance_audit
    @individual_delta_audits = @audit.individual_delta_performance_audits.includes(:performance_audit_with_tag, :performance_audit_without_tag)
    @failed_individual_audits = @audit.individual_performance_audits.failed
    @pending_individual_audits = @audit.individual_performance_audits.pending
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      # { url: tag_audits_path(@tag), text: "#{@tag_version.sha} Audits" },
      { url: performance_audit_tag_audit_path(@tag, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "Individual Performance Audits", active: true }
    )
  end
end