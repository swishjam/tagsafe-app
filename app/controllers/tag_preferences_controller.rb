class TagPreferencesController < LoggedInController
  def update
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    tag.tag_preferences.update(tag_preference_params)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_config_fields",
      partial: "tags/config_fields",
      locals: {
        domain: current_domain,
        tag: tag,
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
        notification_message: "Updated #{tag.try_friendly_name}."
      }
    )
  end

  private

  def tag_preference_params
    params.require(:tag_preference).permit(:release_check_minute_interval, :scheduled_audit_minute_interval)
  end

  # def handle_release_check_interval_update(tag)
  #   overage_estimator = OverageEstimators::ReleaseChecks.new(domain: current_domain, tag: tag, new_release_check_interval: params[:tag_preference][:release_check_minute_interval])
  #   if !params[:tag_preference][:price_increase_confirmed] &&
  #       overage_estimator.price_would_increase? &&
  #       overage_estimator.would_exceed_included_usage_for_subscription_package?
  #     stream_modal(
  #       partial: "overage_estimators/confirmation_modal",
  #       locals: {
  #         feature_title: "Release Check Configuration",
  #         configuration_name: 'release check',
  #         tag: tag,
  #         current_formatted_configuration_value: tag.tag_preferences.release_check_interval_in_words,
  #         formatted_value_being_changed_to: Util.integer_to_interval_in_words(params[:tag_preference][:release_check_minute_interval]),
  #         attr_being_updated: :release_check_minute_interval,
  #         attr_being_updated_value: params[:tag_preference][:release_check_minute_interval],
  #         path_to_update_form: 'overage_estimators/confirm_tag_preference_form',
  #         overage_estimator: overage_estimator,
  #         # included_in_plan: current_domain.subscription_features_configuration.release_checks_included_per_month
  #       }
  #     )
  #   else
  #     update_tag_preference_config(tag)
  #   end
  # end
  
  # def handle_scheduled_audit_interval_update(tag)
  #   overage_estimator = OverageEstimators::AutomatedPerformanceAudits.new(domain: current_domain, tag: tag, new_scheduled_audit_interval: params[:tag_preference][:scheduled_audit_minute_interval])
  #   formatted_value = params[:tag_preference][:scheduled_audit_minute_interval]&.to_i >= 60 ? "every #{params[:tag_preference][:scheduled_audit_minute_interval].to_i / 60} hours" : "every #{params[:tag_preference][:scheduled_audit_minute_interval]} minutes"
  #   if !params[:tag_preference][:price_increase_confirmed] &&
  #       overage_estimator.price_would_increase? &&
  #       (overage_estimator.would_exceed_included_usage_for_subscription_package? ||
  #         overage_estimator.would_exceed_usage_for_subscription_package_next_month?)
  #     stream_modal(
  #       partial: "overage_estimators/confirmation_modal",
  #       locals: {
  #         feature_title: "Automated Audit Configuration",
  #         configuration_name: 'scheduled audit',
  #         tag: tag,
  #         current_formatted_configuration_value: tag.tag_preferences.scheduled_audit_interval_in_words,
  #         formatted_value_being_changed_to: Util.integer_to_interval_in_words(params[:tag_preference][:scheduled_audit_minute_interval]),
  #         attr_being_updated: :scheduled_audit_minute_interval,
  #         attr_being_updated_value: params[:tag_preference][:scheduled_audit_minute_interval],
  #         path_to_update_form: 'overage_estimators/confirm_tag_preference_form',
  #         overage_estimator: overage_estimator,
  #         included_in_plan: current_domain.subscription_features_configuration.automated_performance_audits_included_per_month
  #       }
  #     )
  #   else
  #     update_tag_preference_config(tag)
  #   end
  # end

  # def update_tag_preference_config(tag)
  #   tag.tag_preferences.update(tag_preference_params)
  #   render turbo_stream: turbo_stream.replace(
  #     "tag_#{tag.uid}_config_fields",
  #     partial: "tags/config_fields",
  #     locals: {
  #       domain: current_domain,
  #       tag: tag,
  #       selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
  #       notification_message: "Updated #{tag.try_friendly_name}."
  #     }
  #   )
  # end
end