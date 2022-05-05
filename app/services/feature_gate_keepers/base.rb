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

    def subscription_feature_restriction
      @current_subscription_plan ||= domain.subscription_feature_restriction
    end

    def cant_access!(reason)
      @reason = reason
      return false
    end
  end
end