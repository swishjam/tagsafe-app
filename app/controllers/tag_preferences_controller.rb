class TagPreferencesController < LoggedInController
  def update
    tag = current_domain.tags.find(params[:tag_id])
    attr_being_updated = params[:tag_preference].keys[0]
    priv_params_for_attr_being_updated = params.require(:tag_preference).permit(attr_being_updated.to_sym)
    priv_params_for_attr_being_updated[attr_being_updated] = priv_params_for_attr_being_updated[attr_being_updated] == 'nil' ? nil : 
                                                              priv_params_for_attr_being_updated[attr_being_updated]
    tag_preference = tag.tag_preferences
    if tag_preference.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "Updated #{tag.try_friendly_name} #{attr_being_updated.to_s.split('_').map(&:capitalize).join(' ')}", image: tag.try_image_url)
    else
      current_user.broadcast_notification(message: "Cannot update tag. #{tag_preference.errors.full_messages.join(' ')}", image: tag.try_image_url)
    end
    head :ok
  end
end