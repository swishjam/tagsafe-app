class TriggeredAlertsController < LoggedInController
  def index
    @triggered_alerts = current_domain_user.triggered_alerts
                                            .most_recent_first
                                            .page(params[:page] || 1)
                                            .per(params[:per_page] || 20)
  end

  def show
    @triggered_alert = current_domain_user.triggered_alerts.find(params[:id])
  end
end