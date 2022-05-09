module FeatureGateKeepers
  class CanAccessUptimeMonitoring < Base
    def can_access_feature?
      subscription_feature_restriction.uptime_checks_included_per_month.present?
    end
  end
end