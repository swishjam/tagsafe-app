module FeatureGateKeepers
  class Base
    attr_accessor :domain, :reason

    def initialize(domain)
      @domain = domain
    end

    def can_access_feature?
      raise "#{self.class.to_s} must implement `can_access_feature?` method."
    end

    private

    def subscription_features_configuration
      @subscription_features_configuration ||= delinquent_subscription_plan.present? ? SubscriptionFeaturesConfiguration.FOR_DELINQUENT_SUBSCRIPTION : domain.subscription_features_configuration
    end

    def delinquent_subscription_plan
      @delinquent_subscription_plan ||= domain.current_subscription_plan.delinquent? ? 
                                          domain.current_subscription_plan : nil
    end


    def cant_access!(reason)
      @reason = reason
      return false
    end
  end
end