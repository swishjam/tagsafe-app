class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.release_check_minute_interval DESC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
                          .page(params[:page]).per(params[:per_page] || 10)
  end

  def billing    
    @next_invoice = Stripe::Invoice.upcoming({ subscription: current_domain.current_subscription_plan.stripe_subscription_id, expand: ['lines.data.price.product'] }) unless current_domain.current_subscription_plan.canceled?
    @default_payment_method = Stripe::PaymentMethod.retrieve(current_domain.stripe_payment_method_id) unless current_domain.stripe_payment_method_id.nil?
  end
end