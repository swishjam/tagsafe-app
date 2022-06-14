class AlertConfigurationDomainUsersController < LoggedInController
  before_action :find_alert_configuration

  def index
    @selected_domain_users = @alert_configuration.domain_users
    @unselected_domain_users = current_domain.domain_users.where.not(id: @selected_domain_users.collect(&:id))
  end

  private

  def find_alert_configuration
    @alert_configuration = current_domain.alert_configurations.find_by(uid: params[:uid])
  end
end