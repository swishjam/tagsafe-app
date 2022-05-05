module SubscriptionUsageAnalyzer
  class UsageForMonth
    def initialize(domain)
      @domain = domain
    end

    def send_usage_warning_email_if_necessary
    end

    def send_exceeded_usage_email_if_necessary
    end
  end
end