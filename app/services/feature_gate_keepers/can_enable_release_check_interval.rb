module FeatureGateKeepers
  class CanEnableReleaseCheckInterval < Base
    def can_access_feature?(interval)
      if delinquent_subscription_plan.present?
        cant_access!("Tagsafe has been unable to charge your payment method on file. In order to access release monitoring you must updated your payment method.")
      elsif subscription_features_configuration.min_release_check_minute_interval.nil? || 
              subscription_features_configuration.min_release_check_minute_interval > interval
        cant_access!("Your susbcription plan only allows for release monitoring intervals at #{subscription_features_configuration.min_release_check_minute_interval_in_words} minute cadence or higher.")
      else
        true
      end
    end
  end
end