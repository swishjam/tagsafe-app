module FeatureGateKeepers
  class HasAdvancedPerformanceAuditConfigurations < Base
    def can_access_feature?
      return true unless delinquent_subscription_plan.present? || !subscription_feature_restriction.has_advance_performance_audit_configurations
      suffix = delinquent_subscription_plan.present? && delinquent_subscription_plan.package_type.pro? ? 
        " Your payment method is invalid, so your account is now considered a Starter Plan until you provide an updated payment method." : nil
      cant_access!("Advanced audit configurations are only available on the Pro Plan.#{suffix}")
    end
  end
end