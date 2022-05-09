module FeatureGateKeepers
  class CanEnableReleaseCheckInterval < Base
    def can_access_feature?(interval)
      if delinquent_subscription_plan.present?
        SubscriptionFeatureRestriction::DEFAULTS_FOR_PACKAGE[:starter][:min_release_check_minute_interval] <= interval
      else
        subscription_feature_restriction.min_release_check_minute_interval.nil? || 
          subscription_feature_restriction.min_release_check_minute_interval <= interval
      end
    end

    def can_pay_for_access?
      false
    end
  end
end