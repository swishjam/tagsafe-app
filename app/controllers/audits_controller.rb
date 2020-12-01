class AuditsController < LoggedInController
  def index
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    @script_change = ScriptChange.find(params[:script_change_id])
    @audits = @script_subscriber.audits_by_script_change(@script_change, include_pending_lighthouse_audits: true, include_pending_test_suites: true, include_failed_lighthouse_audits: true)
    @primary_audit = @script_subscriber.primary_audit_by_script_change(@script_change)
    render_breadcrumbs(
      { url: scripts_path, text: "Monitor Center" },
      { url: script_subscriber_path(@script_subscriber), text: "#{@script_subscriber.try_friendly_name} Details" },
      { text: "#{@script_change.created_at.formatted_short} Audits", active: true }
    )
  end

  def show
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    @script_change = ScriptChange.find(params[:script_change_id])
    @audit = Audit.find(params[:id])
    @previous_audit = @script_subscriber.primary_audit_by_script_change(@script_change.previous_change)
    @count_of_audits_for_script_change = @script_subscriber.audits_by_script_change(@script_change, 
                                                                                    include_pending_lighthouse_audits: true, 
                                                                                    include_pending_test_suites: true, 
                                                                                    include_failed_lighthouse_audits: true).count
    render_breadcrumbs(
      { url: scripts_path, text: "Monitor Center" },
      { url: script_subscriber_path(@script_subscriber), text: "#{@script_subscriber.try_friendly_name} Details" },
      { url: script_subscriber_script_change_audits_path(@script_subscriber, @script_change), text: "#{@script_change.created_at.formatted_short} Change Audits" },
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