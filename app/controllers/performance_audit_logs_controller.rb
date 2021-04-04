class PerformanceAuditLogsController < LoggedInController
  def index
    @audit = Audit.find(params[:audit_id])
    permitted_to_view?(@audit)
    @with_tag_log = @audit.performance_audit_with_tag.performance_audit_logs
    @without_tag_log = @audit.performance_audit_without_tag.performance_audit_logs
    @tag = Tag.find(params[:tag_id])
    @tag_version = TagVersion.find(params[:tag_version_id])
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.created_at.formatted_short} Change Audits" },
      { url: tag_tag_version_audit_path(@tag, @tag_version, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "Performance Audit Logs", active: true }
    )
  end

  # def show
  #   @log = PerformanceAuditLog.inclludes(performance_audit: [:audit]).find(params[:id])
  #   permitted_to_view?(@log.performance_audit.audit)
  # end
end