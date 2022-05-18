class SubscriptionPlansController < LoggedInController
  skip_before_action :ensure_subscription_plan, only: [:select, :create]
  
  def select
    @hide_navigation = true
  end

  def create
    SubscriptionMaintainer::Enroller.new(
      current_domain,
      subscription_package: params[:domain][:subscription_package].to_s, 
      billing_interval: params[:domain][:billing_interval].to_s,
      free_trial_days: 14
    ).enroll!
    redirect_to tags_path
  end

  def update
    SubscriptionMaintainer::Remover.new(domain).cancel_current_subscription!
    subscription_applier = SubscriptionMaintainer::Enroller.new(
      current_domain,
      subscription_package: params[:domain][:subscription_package], 
      billing_interval: params[:domain][:billing_interval]
    ).enroll!
  end

  def cancel
    subscription_plan = current_domain.subscription_plans.find_by(uid: params[:uid])
    subscription_plan.cancel!
    redirect_to settings_billing_path
  end
end