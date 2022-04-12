class TriggeredAlertsController < LoggedInController
  def index
    unless current_user.nil?
      @triggered_alerts = current_domain_user.triggered_alerts
                                              .most_recent_first
                                              .page(params[:page] || 1)
                                              .per(params[:per_page] || 20)
    end
  end

  def show
    @triggered_alert = current_domain_user.triggered_alerts.find_by(uid: params[:uid])
  end
end