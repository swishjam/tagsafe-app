module FeatureGateKeepers
  class HasAdvancedPerformanceAuditConfigurations < Base
    def can_access_feature?
      return true unless delinquent_subscription_plan.present? || !subscription_features_configuration.has_advance_performance_audit_configurations
      cant_access!("Advanced audit configurations are only available on the Pro Plan.#{suffix}")
    end
  end
end