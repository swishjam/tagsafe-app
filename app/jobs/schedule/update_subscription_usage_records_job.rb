module Schedule
  class UpdateSubscriptionUsageRecordsJob
    def perform
      Domain.registered.each do |domain|
        SubscriptionMaintainer::UsageRecordUpdater.new(domain).send_usage_records_to_stripe
      end
    end
  end
end