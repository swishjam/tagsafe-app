module FeatureGateKeepers
  class CanTurnUptimeMonitoringOnForTagCheckRegion < Base
    def can_access_feature?(tag_check_region)
      return false if subscription_feature_restriction.uptime_regions_availability == 'none'
      return true if subscription_feature_restriction.uptime_regions_availability == 'global'
      tag_check_region.is_considered_regional_availability?
    end
  end
end