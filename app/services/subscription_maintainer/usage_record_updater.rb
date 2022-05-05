module SubscriptionMaintainer
  class UsageRecordUpdater
    def initialize(domain, usage_records_start_date: DateTime.yesterday.beginning_of_day, usage_records_end_date: DateTime.yesterday.end_of_day)
      @domain = domain
      @billed_amount_in_cents = 0
      @usage_records_start_date = usage_records_start_date
      @usage_records_end_date = usage_records_end_date
    end

    def send_usage_records_to_stripe
      Rails.logger.info "SubscriptionMaintainer::UsageRecordUpdater sending usage record data for #{@usage_records_start_date} - #{@usage_records_end_date}"
      if @domain.current_usage_based_subscription_plan
        @domain.current_usage_based_subscription_plan.subscription_prices.each{ |subscription_price| create_usage_record!(subscription_price) }
        @domain.subscription_usage_record_updates.create!(
          subscription_plan: @domain.current_usage_based_subscription_plan,
          billed_amount_in_cents: @billed_amount_in_cents,
          bill_start_datetime: @usage_records_start_date,
          bill_end_datetime: @usage_records_end_date
        )
      else
        Rails.logger.error "Unable to bill Domain #{@domain.uid}, does not have a current subscriptin plan."
      end
    end
  
    private

    def create_usage_record!(subscription_price)
      stripe_usage_record = Stripe::SubscriptionItem.create_usage_record(
        subscription_price.stripe_subscription_item_id,
        {
          quantity: num_usage_records_for(subscription_price.subscription_price_option.class.billable_model),
          action: 'increment'
        },
        { idempotency_key: "#{subscription_price.uid}_#{@usage_records_start_date.to_s}-#{@usage_records_end_date.to_s}" }
      )
      # @billed_amount_in_cents += stripe_usage_record.quantity * subscription_price.subscription_price_option.price_in_cents
    end

    def num_usage_records_for(billable_model)
      billable_model.billable_for_domain(@domain)
                      .more_recent_than_or_equal_to(@usage_records_start_date, timestamp_column: :"#{billable_model.table_name}.created_at")
                      .older_than_or_equal_to(@usage_records_end_date, timestamp_column: :"#{billable_model.table_name}.created_at")
                      .count
    end
  end
end