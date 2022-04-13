module SubscriptionMaintainer
  class Applier
    def initialize(domain)
      @domain = domain
    end

    def cancel_current_subscription!
      UsageRecordUpdater.new(@domain, usage_records_start_date: DateTime.now.beginning_of_day, usage_records_end_date: DateTime.now.end_of_day).send_usage_records_to_stripe
      stripe_subscription = Stripe::Subscription.delete(@domain.current_subscription_plan.stripe_subscription_id, invoice_now: true)
      @domain.current_subscription_plan.update_status_to(stripe_subscription.status)
      @domain.current_subscription_plan.update!(current: false)
      apply_default_subscription_for_domain
    end

    def apply_default_subscription_for_domain
      return if @domain.current_subscription_plan.present?
      stripe_subscription = Stripe::Subscription.create(
        customer: @domain.stripe_customer_id,
        items: [
          { price: PerAutomatedPerformanceAuditSubscriptionPrice.DEFAULT.stripe_price_id },
          { price: PerAutomatedTestRunSubscriptionPrice.DEFAULT.stripe_price_id },
          { price: PerTagCheckSubscriptionPrice.DEFAULT.stripe_price_id }
        ],
        metadata: { tagsafe_domain_id: @domain.id, tagsafe_domain_url: @domain.url }
      )
      SubscriptionPlan.create(
        domain: @domain,
        stripe_subscription_id: stripe_subscription.id,
        current: true,
        status: stripe_subscription.status,
        subscription_plan_items_attributes: [
          { stripe_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(PerAutomatedPerformanceAuditSubscriptionPrice.DEFAULT), subscription_price: PerAutomatedPerformanceAuditSubscriptionPrice.DEFAULT },
          { stripe_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(PerAutomatedTestRunSubscriptionPrice.DEFAULT), subscription_price: PerAutomatedTestRunSubscriptionPrice.DEFAULT },
          { stripe_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(PerTagCheckSubscriptionPrice.DEFAULT), subscription_price: PerTagCheckSubscriptionPrice.DEFAULT },
        ]
      )
    end

    # def set_subscription_for_domain(subscription_option)
    #   if @domain.current_subscription_plan.present?
    #     update_existing_stripe_subscription_for_domain(subscription_option)
    #   else
    #     create_new_stripe_subscription_for_domain(subscription_option)
    #   end
    # end
  
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
        stripe_flat_fee_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(subscription_option.stripe_flat_fee_monthly_price_id),
        stripe_performance_audit_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(subscription_option.stripe_performance_audit_monthly_price_id),
        stripe_tag_check_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(subscription_option.stripe_tag_check_monthly_price_id),
        stripe_functional_test_subscription_item_id: stripe_subscription.subscription_item_for_tagsafe_subscription_price(subscription_option.stripe_functional_test_monthly_price_id)
      )
    end
  
    def update_existing_stripe_subscription_for_domain(subscription_option)
      stripe_subscription = Stripe::Subscription.update(
        @domain.current_subscription_plan.stripe_subscription_id,
        {
          cancel_at_period_end: false,
          # proration_behavior: 'create_prorations',
          proration_behavior: 'always_invoice',
          # payment_behavior: 'allow_incomplete',
          items: [
            { price: subscription_option.stripe_flat_fee_monthly_price_id, id: @domain.current_subscription_plan.stripe_flat_fee_subscription_item_id },
            { price: subscription_option.stripe_tag_check_monthly_price_id, id: @domain.current_subscription_plan.stripe_tag_check_subscription_item_id },
            { price: subscription_option.stripe_performance_audit_monthly_price_id, id: @domain.current_subscription_plan.stripe_performance_audit_subscription_item_id },
            { price: subscription_option.stripe_functional_test_monthly_price_id, id: @domain.current_subscription_plan.stripe_functional_test_subscription_item_id }
          ]
        }
      )
      @domain.current_subscription_plan.update!(
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

class Stripe::Subscription
  def subscription_item_for_tagsafe_subscription_price(subscription_price)
    items.data.find{ |item| item.price.id == subscription_price.stripe_price_id }&.id
  end
end