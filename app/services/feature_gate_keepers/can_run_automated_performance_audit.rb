module FeatureGateKeepers
  class CanRunAutomatedPerformanceAudit < Base
    def can_access_feature?
      return true unless delinquent_subscription_plan.present? || subscription_feature_restriction.max_automated_performance_audits_per_month.present?
      return true unless num_automated_performance_audits_for_domain_this_month >= max_allowed_manual_performance_audits_per_month
      cant_access!(
        <<~REASON
          #{delinquent_subscription_plan ? "Your #{delinquent_subscription_plan.package_type.capitalize} Plan is invalid. Until we are able to process a successful payment, your Tagsafe account will operate as a Starter Plan. " : nil}Your account reached 
          the maximum number of automated performance audits (#{num_automated_performance_audits_for_domain_this_month}) while on the Starter Plan. Consider upgrading your plan in order to get access to unlimited manual performance audits.
        REASON
      )
    end

    private

    def max_allowed_manual_performance_audits_per_month
      @max_allowed_manual_performance_audits_per_month ||= delinquent_subscription_plan ? 
                                                              SubscriptionFeatureRestriction::DEFAULTS_FOR_PACKAGE[:starter][:max_automated_performance_audits_per_month] : 
                                                              subscription_feature_restriction.max_automated_performance_audits_per_month
    end

    def delinquent_subscription_plan
      @delinquent_subscription_plan ||= domain.current_saas_subscription_plan.delinquent? ? 
                                          domain.current_saas_subscription_plan :
                                            domain.current_usage_based_subscription_plan.delinquent? ? 
                                              domain.current_usage_based_subscription_plan : 
                                              nil
    end

    def num_automated_performance_audits_for_domain_this_month
      @num_automated_performance_audits_for_domain_this_month ||= domain.audits
                                                                          .automated
                                                                          .successful_performance_audit
                                                                          .more_recent_than_or_equal_to(Time.current.beginning_of_month)
                                                                          .count
    end
  end
end