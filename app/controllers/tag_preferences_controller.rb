class TagPreferencesController < LoggedInController
  def update
    tag = current_domain.tags.find(params[:tag_id])
    attr_being_updated = params[:tag_preference].keys[0]
    priv_params_for_attr_being_updated = params.require(:tag_preference).permit(attr_being_updated.to_sym)
    tag_preference = tag.tag_preferences
    if tag_preference.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "Updated #{tag.try_friendly_name} #{attr_being_updated.to_s.split('_').map(&:capitalize).join(' ')}", image: tag.try_image_url)
    else
      current_user.broadcast_notification(message: "Cannot update tag. #{tag_preference.errors.full_messages.join(' ')}", image: tag.try_image_url)
    end
    head :ok
  end

  # private

  # def tag_preference_params
  #   params.require(:tag_preference).permit(
  #     :enabled, 
  #     :is_allowed_third_party_tag, 
  #     :is_third_party_tag, 
  #     :should_log_tag_checks, 
  #     :consider_query_param_changes_new_tag, 
  #     :throttle_minute_threshold
  #   )
  # end
end