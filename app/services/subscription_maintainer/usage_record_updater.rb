module SubscriptionMaintainer
  class UsageRecordUpdater
    def initialize(domain, usage_records_start_date: DateTime.yesterday.beginning_of_day, usage_records_end_date: DateTime.yesterday.end_of_day)
      @domain = domain
      @usage_records_start_date = usage_records_start_date
      @usage_records_end_date = usage_records_end_date
    end

    def send_usage_records_to_stripe
      Rails.logger.info "SubscriptionMaintainer::UsageRecordUpdater sending usage record data for #{@usage_records_start_date} - #{@usage_records_end_date}"
      return if @domain.selected_subscription_option.basic?
      update_tag_check_usage_records_for_domain
      update_performance_audit_usage_records_for_domain
      update_functional_tests_usage_records_for_domain
    end
  
    private
  
    def update_performance_audit_usage_records_for_domain
      Stripe::SubscriptionItem.create_usage_record(
        @domain.subscription_plan.stripe_tag_check_subscription_item_id,
        usage_records_results_for(AverageDeltaPerformanceAudit.billable_for_domain(@domain), :'delta_performance_audits.created_at')
      )
    end
  
    def update_tag_check_usage_records_for_domain
      Stripe::SubscriptionItem.create_usage_record(
        @domain.subscription_plan.stripe_performance_audit_subscription_item_id,
        usage_records_results_for(TagCheck.billable_for_domain(@domain), :'tag_checks.created_at')
      )
    end

    def update_functional_tests_usage_records_for_domain
      Stripe::SubscriptionItem.create_usage_record(
        @domain.subscription_plan.stripe_functional_test_subscription_item_id,
        usage_records_results_for(TestRunWithTag.billable_for_domain(@domain), :'test_runs.enqueued_at')
      )
    end
  
    def usage_records_results_for(records, timestamp_column = :created_at)
      { 
        quantity: records.more_recent_than_or_equal_to(@usage_records_start_date, timestamp_column: timestamp_column)
                          .older_than_or_equal_to(@usage_records_end_date, timestamp_column: timestamp_column)
                          .count, 
        # timestamp: @usage_records_end_date.to_i
      }
    end
  end
end