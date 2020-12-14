class ScriptSubscriberAllowedPerformanceAuditTagsController < LoggedInController
  def create
    allowed = ScriptSubscriberAllowedPerformanceAuditTag.create(allowed_params)
    if allowed.valid?
      display_toast_message("Added #{allowed.allowed_script_subscriber.try_friendly_name} to allowed third party tags for #{allowed.performance_audit_script_subscriber.try_friendly_name} audits.")
    else
      display_toast_errors(allowed.errors.full_messages)
    end
    redirect_to request.referrer
  end
  
    
    def destroy
      allowed = ScriptSubscriberAllowedPerformanceAuditTag.find(params[:id])
      allowed.destroy!
      display_toast_message("Removed #{allowed.allowed_script_subscriber.try_friendly_name} allowed tag.")
      redirect_to request.referrer
    end

  private
  def allowed_params
    params.require(:script_subscriber_allowed_performance_audit_tag).permit(:performance_audit_script_subscriber_id, :allowed_script_subscriber_id)
  end
end