class TagPreferencesController < LoggedInController
  def update
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    attr_being_updated = params[:tag_preference].keys[0]
    priv_params_for_attr_being_updated = params.require(:tag_preference).permit(attr_being_updated.to_sym)
    priv_params_for_attr_being_updated[attr_being_updated] = priv_params_for_attr_being_updated[attr_being_updated] == 'nil' ? nil : 
                                                              priv_params_for_attr_being_updated[attr_being_updated]
    tag_preference = tag.tag_preferences
    if tag_preference.update(priv_params_for_attr_being_updated)
      respond_with_notification(message: "Updated #{tag.try_friendly_name} #{attr_being_updated.to_s.split('_').map(&:capitalize).join(' ')}", image: tag.try_image_url)
    else
      respond_with_notification(message: "Cannot update tag. #{tag_preference.errors.full_messages.join(' ')}", image: tag.try_image_url)
    end
  end
end