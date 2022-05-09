module FeatureGateKeepers
  class Base
    attr_accessor :domain, :reason

    def initialize(domain)
      @domain = domain
    end

    def can_access_feature?
      raise "#{self.class.to_s} must implement `can_access_feature?` method."
    end

    def can_pay_for_access?
      raise "#{self.class.to_s} must implement `can_pay_for_access?` method."
    end

    private

    def subscription_feature_restriction
      @subscription_feature_restriction ||= delinquent_subscription_plan.present? ? SubscriptionFeatureRestriction.FOR_DELINQUENT_SUBSCRIPTION : domain.subscription_feature_restriction
    end

    def delinquent_subscription_plan
      @delinquent_subscription_plan ||= domain.current_saas_subscription_plan.delinquent? ? 
                                          domain.current_saas_subscription_plan :
                                            domain.current_usage_based_subscription_plan.delinquent? ? 
                                              domain.current_usage_based_subscription_plan : 
                                              nil
    end


    def cant_access!(reason)
      @reason = reason
      return false
    end
  end
end