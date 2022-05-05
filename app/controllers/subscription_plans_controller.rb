class SubscriptionPlansController < LoggedInController
  skip_before_action :ensure_subscription_plan, only: [:select, :create]
  
  def select
    @hide_navigation = true
  end

  def create
    SubscriptionMaintainer::Applier.new(current_domain).apply_subscription_package_to_domain(
      subscription_package: params[:domain][:subscription_package], 
      billing_interval: params[:domain][:billing_interval],
      free_trial_days: params[:domain][:subscription_package].to_sym == SubscriptionPlan::Package.STARTER ? nil : 14
    )
    redirect_to tags_path
  end

  def edit
    stream_modal(
      partial: 'subscription_plans/subscription_options_modal',
      locals: {
        current_package: current_domain.current_saas_subscription_plan.package_type,
        current_billing_interval: current_domain.current_saas_subscription_plan.subscription_price
      }
    )
  end

  def update
    subscription_applier = SubscriptionMaintainer::Applier.new(current_domain)
    subscription_applier.cancel_current_subscription!
    subscription_applier.apply_subscription_package_to_domain(
      subscription_package: params[:domain][:subscription_package], 
      billing_interval: params[:domain][:billing_interval]
    )
  end

  def cancel
    subscription_plan = current_domain.subscription_plans.find_by(uid: params[:uid])
    subscription_plan.cancel!
    redirect_to settings_billing_path
  end
end