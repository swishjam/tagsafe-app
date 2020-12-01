class NotificationPreferencesController < LoggedInController
  def index
    @script_subscriptions = current_domain.script_subscriptions
  end
end