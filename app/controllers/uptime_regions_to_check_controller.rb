class UptimeRegionsToCheckController < LoggedInController
  def create
    uptime_region_to_check = tag.uptime_regions_to_check.create(uptime_region_id: params[:uptime_region_id])
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_config_fields",
      partial: "tags/config_fields",
      locals: {
        domain: current_domain,
        tag: tag,
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
        notification_message: "Added #{uptime_region_to_check.uptime_region.location} to #{tag.try_friendly_name}'s uptime regions."
      }
    )
  end

  def destroy
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    uptime_region_to_check = UptimeRegionToCheck.find_by(uid: params[:uid])
    uptime_region_to_check.destroy
    render turbo_stream: turbo_stream.replace(
      "new_tag_#{tag.uid}_uptime_regions_to_check",
      partial: 'uptime_regions_to_check/new',
      locals:{ 
        tag: tag, 
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag) 
      }
    )
  end

  # def create
  #   tag = current_domain.tags.find_by(uid: params[:tag_uid])
  #   overage_estimator = OverageEstimators::UptimeChecks.new(current_domain)
  #   if !params[:price_increase_confirmed] && overage_estimator.would_exceed_included_usage_for_subscription_package?
  #     uptime_region = UptimeRegion.find(params[:uptime_region_id])
  #     stream_modal(
  #       partial: "overage_estimators/confirmation_modal",
  #       locals: {
  #         feature_title: "Uptime Monitoring Configuration",
  #         configuration_name: 'uptime check',
  #         tag: tag,
  #         current_formatted_configuration_value: "#{tag.uptime_regions_to_check.count} regions",
  #         formatted_value_being_changed_to: "#{tag.uptime_regions_to_check.count + 1} regions",
  #         path_to_update_form: 'overage_estimators/confirm_uptime_region_to_check_form',
  #         attr_being_updated: :uptime_region_id,
  #         attr_being_updated_value: params[:uptime_region_id],
  #         overage_estimator: overage_estimator,
  #         included_in_plan: current_domain.subscription_features_configuration.uptime_checks_included_per_month
  #       }
  #     )
  #   else
  #     uptime_region_to_check = tag.uptime_regions_to_check.create(uptime_region_id: params[:uptime_region_id])
  #     render turbo_stream: turbo_stream.replace(
  #       "tag_#{tag.uid}_config_fields",
  #       partial: "tags/config_fields",
  #       locals: {
  #         domain: current_domain,
  #         tag: tag,
  #         selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
  #         notification_message: "Added #{uptime_region_to_check.uptime_region.location} to #{tag.try_friendly_name}'s uptime regions."
  #       }
  #     )
  #   end
  # end
end