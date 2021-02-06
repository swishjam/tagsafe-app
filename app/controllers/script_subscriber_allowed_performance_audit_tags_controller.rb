class ScriptSubscriberAllowedPerformanceAuditTagsController < LoggedInController
  def create
    params[:script_subscriber_allowed_performance_audit_tag][:script_subscriber_id] = params[:script_subscriber_id]
    allowed = ScriptSubscriberAllowedPerformanceAuditTag.create(allowed_params)
    if allowed.valid?
      display_toast_message("Added #{allowed.url_pattern} to allowed third party tag URL patterns for #{allowed.script_subscriber.try_friendly_name} audits.")
    else
      display_toast_errors(allowed.errors.full_messages)
    end
    redirect_to request.referrer
  end
  
    
    def destroy
      allowed = ScriptSubscriberAllowedPerformanceAuditTag.find(params[:id])
      allowed.destroy!
      display_toast_message("Removed #{allowed.url_pattern} allowed tag URL pattern.")
      redirect_to request.referrer
    end

  private
  def allowed_params
    params.require(:script_subscriber_allowed_performance_audit_tag).permit(:script_subscriber_id, :url_pattern)
  end
end