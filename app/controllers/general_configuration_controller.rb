class GeneralConfigurationController < LoggedInController
  def update
    attr_being_update = params[:general_configuration].keys[0]
    priv_params_for_attr_being_updated = params.require(:general_configuration).permit(attr_being_update.to_sym)
    if current_domain.general_configuration.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "#{attr_being_update.split('_').map(&:capitalize).join(' ')} setting updated.")
    else
      current_user.broadcast_notification(message: "Unable to update setting: #{current_domain.general_configuration.errors.join('. ')}")
    end
    head :ok
  end
end