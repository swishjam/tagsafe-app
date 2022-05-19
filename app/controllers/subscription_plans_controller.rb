class SubscriptionPlansController < LoggedInController
  skip_before_action :ensure_subscription_plan, only: [:select, :create]
  
  def select
    can_select = !current_domain.has_current_subscription_plan? ||
                  current_domain.current_subscription_plan.canceled? ||
                  current_domain.current_subscription_plan.delinquent? ||
                  params[:update]
    redirect_to tags_path unless can_select
    @hide_navigation = true
  end

  def create
    SubscriptionMaintainer::Enroller.new(
      current_domain,
      subscription_package: params[:domain][:subscription_package].to_s, 
      billing_interval: params[:domain][:billing_interval].to_s,
      free_trial_days: current_domain.subscription_plans.none? ? 14 : 0
    ).enroll!
    redirect_to tags_path
  end

  def update
    subscription_applier = SubscriptionMaintainer::Updater.new(
      current_domain,
      subscription_package: params[:domain][:subscription_package], 
      billing_interval: params[:domain][:billing_interval]
    ).update_current_subscription!
    flash[:flash_notification] = "Your subscription package has been updated to the #{params[:domain][:subscription_package].capitalize} Plan."
    redirect_to settings_billing_path
  end

  def cancel
    SubscriptionMaintainer::Remover.new(current_domain).cancel_current_subscription!
    redirect_to settings_billing_path
  end
end