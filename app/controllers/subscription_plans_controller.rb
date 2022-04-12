class SubscriptionPlansController < LoggedInController
  def cancel
    subscription_plan = current_domain.subscription_plans.find_by(uid: params[:uid])
    subscription_plan.cancel!
    redirect_to settings_billing_path
  end
end