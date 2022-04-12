class TagAllowedPerformanceAuditThirdPartyUrlsController < LoggedInController
  def create
    params[:tag_allowed_performance_audit_third_party_url][:tag_id] = params[:tag_id]
    allowed = TagAllowedPerformanceAuditThirdPartyUrl.create(allowed_params)
    if allowed.valid?
      display_toast_message("Added #{allowed.url_pattern} to allowed third party tag URL patterns for #{allowed.tag.try_friendly_name} audits.")
    else
      display_toast_errors(allowed.errors.full_messages)
    end
    redirect_to request.referrer
  end
  
    
  def destroy
    allowed = TagAllowedPerformanceAuditThirdPartyUrl.find_by(uid: params[:uid])
    allowed.destroy
    display_toast_message("Removed #{allowed.url_pattern} allowed tag URL pattern.")
    redirect_to request.referrer
  end

  private
  def allowed_params
    params.require(:tag_allowed_performance_audit_third_party_url).permit(:tag_id, :url_pattern)
  end
end