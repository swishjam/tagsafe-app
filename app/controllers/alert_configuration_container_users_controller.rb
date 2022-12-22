class AlertConfigurationContainerUsersController < LoggedInController
  before_action :find_alert_configuration

  def index
    @selected_container_users = @alert_configuration.container_users
    @unselected_container_users = current_container.container_users.where.not(id: @selected_container_users.collect(&:id))
  end

  private

  def find_alert_configuration
    @alert_configuration = current_container.alert_configurations.find_by(uid: params[:uid])
  end
end