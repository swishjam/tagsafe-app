class DefaultAuditConfigurationController < LoggedInController
  def update
    attr_being_update = params[:default_audit_configuration].keys[0]
    priv_params_for_attr_being_updated = params.require(:default_audit_configuration).permit(attr_being_update.to_sym)
    if current_domain.default_audit_configuration.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "#{attr_being_update.split('_').map(&:capitalize).join(' ')} setting updated.")
    else
      current_user.broadcast_notification(message: "Unable to update setting: #{current_domain.default_audit_configuration.errors..join('. ')}")
    end
    head :ok
  end

  private

  def include_performance_audit_params
    params.require(:default_audit_configuration).permit(:include_performance_audit)
  end
end