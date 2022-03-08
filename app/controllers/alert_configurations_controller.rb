class AlertConfigurationsController < LoggedInController
  def show
    @alert_configuration = current_domain_user.alert_configurations.find(params[:id])
  end

  def update
    alert_configuration = current_domain_user.alert_configurations.find(params[:id])
    attr_being_updated = params[:alert_configuration].keys[0]
    priv_params_for_attr_being_updated = params.require(:alert_configuration).permit(attr_being_updated.to_sym)
    if alert_configuration.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "Alert settings updated.")
    else
      current_user.broadcast_notification(message: alert_configuration.errors.full_sentences.join('\n'))
    end
    head :ok
  end
end