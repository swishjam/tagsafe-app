module SubscriptionMaintainer
  class Applier
    def initialize(domain)
      @domain = domain
    end

    def set_subscription_for_domain(subscription_option)
      if @domain.subscription_plan.present?
        update_existing_stripe_subscription_for_domain(subscription_option)
      else
        create_new_stripe_subscription_for_domain(subscription_option)
      end
    end
  
    private
  
    def create_new_stripe_subscription_for_domain(subscription_option)
      stripe_subscription = Stripe::Subscription.create(
        customer: @domain.stripe_customer_id,
        items: [
          { price: subscription_option.stripe_flat_fee_monthly_price_id },
          { price: subscription_option.stripe_tag_check_monthly_price_id },
          { price: subscription_option.stripe_performance_audit_monthly_price_id },
          { price: subscription_option.stripe_functional_test_monthly_price_id }
        ],
        metadata: { 
          tagsafe_domain_id: @domain.id,
          tagsafe_domain_url: @domain.url
        }
      )
      SubscriptionPlan.create(
        domain: @domain,
        subscription_option: subscription_option,
        stripe_subscription_id: stripe_subscription.id,
        status: stripe_subscription.status,
        stripe_flat_fee_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_flat_fee_monthly_price_id),
        stripe_performance_audit_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_performance_audit_monthly_price_id),
        stripe_tag_check_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_tag_check_monthly_price_id),
        stripe_functional_test_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_functional_test_monthly_price_id)
      )
    end
  
    def update_existing_stripe_subscription_for_domain(subscription_option)
      stripe_subscription = Stripe::Subscription.update(
        @domain.subscription_plan.stripe_subscription_id,
        {
          cancel_at_period_end: false,
          # proration_behavior: 'create_prorations',
          proration_behavior: 'always_invoice',
          # payment_behavior: 'allow_incomplete',
          items: [
            { price: subscription_option.stripe_flat_fee_monthly_price_id, id: @domain.subscription_plan.stripe_flat_fee_subscription_item_id },
            { price: subscription_option.stripe_tag_check_monthly_price_id, id: @domain.subscription_plan.stripe_tag_check_subscription_item_id },
            { price: subscription_option.stripe_performance_audit_monthly_price_id, id: @domain.subscription_plan.stripe_performance_audit_subscription_item_id },
            { price: subscription_option.stripe_functional_test_monthly_price_id, id: @domain.subscription_plan.stripe_functional_test_subscription_item_id }
          ]
        }
      )
      @domain.subscription_plan.update!(
        subscription_option: subscription_option,
        status: stripe_subscription.status,
        stripe_flat_fee_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_flat_fee_monthly_price_id),
        stripe_performance_audit_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_performance_audit_monthly_price_id),
        stripe_tag_check_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_tag_check_monthly_price_id),
        stripe_functional_test_subscription_item_id: get_subscription_item_id_for_price_id(stripe_subscription, subscription_option.stripe_functional_test_monthly_price_id)
      )
    end
  
    def get_subscription_item_id_for_price_id(stripe_subscription, price_id)
      stripe_subscription.items.data.find{ |item| item.price.id == price_id }&.id
    end
  end
end