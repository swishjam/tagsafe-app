class PerformanceAuditLogsController < LoggedInController
  def index
    @audit = Audit.find(params[:audit_id])
    permitted_to_view?(@audit)
    @with_tag_log = @audit.performance_audit_with_tag.performance_audit_logs
    @without_tag_log = @audit.performance_audit_without_tag.performance_audit_logs
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    @script_change = ScriptChange.find(params[:script_change_id])
    render_breadcrumbs(
      { url: scripts_path, text: "Monitor Center" },
      { url: script_subscriber_path(@script_subscriber), text: "#{@script_subscriber.try_friendly_name} Details" },
      { url: script_subscriber_script_change_audits_path(@script_subscriber, @script_change), text: "#{@script_change.created_at.formatted_short} Change Audits" },
      { url: script_subscriber_script_change_audit_path(@script_subscriber, @script_change, @audit), text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "Performance Audit Logs", active: true }
    )
  end

  # def show
  #   @log = PerformanceAuditLog.inclludes(performance_audit: [:audit]).find(params[:id])
  #   permitted_to_view?(@log.performance_audit.audit)
  # end
end