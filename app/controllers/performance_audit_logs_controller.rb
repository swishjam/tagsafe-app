class PerformanceAuditLogsController < LoggedInController
  def index
    @audit = Audit.find_by(uid: params[:audit_uid])
    permitted_to_view?(@audit)
    @performance_audits_with_tag = @audit.performance_audits_with_tag.includes(:performance_audit_log)
    @performance_audits_without_tag = @audit.performance_audits_without_tag.includes(:performance_audit_log)
    @tag = Tag.find_by(uid: params[:tag_uid])
    @tag_version = TagVersion.find_by(uid: params[:tag_version_uid])
    # render_breadcrumbs(
    #   { url: tags_path, text: "Monitor Center" },
    #   { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
    #   { url: tag_audits_path(@tag, @tag_version), text: "#{@tag_version.created_at.formatted_short} Change Audits" },
    #   { url: tag_audit_path(@tag, @tag_version, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
    #   { text: "Performance Audit Logs", active: true }
    # )
  end
end