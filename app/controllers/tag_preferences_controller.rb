class TagPreferencesController < LoggedInController
  def edit
    @tag_preference = TagPreference.includes(:tag).find(params[:id])
    @tag = @tag_preference.tag
    permitted_to_view?(@tag)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def update
    tag_preference = TagPreference.includes(:tag).find(params[:id])
    if tag_preference.update(tag_preference_params)
      current_user.broadcast_notification(message: "Updated #{tag_preference.tag.try_friendly_name}", image: tag_preference.tag.try_image_url)
    else
      current_user.broadcast_notification(message: "Cannot update tag. #{tag_preference.errors.full_messages.join(' ')}", image: tag_preference.tag.try_image_url)
    end
    render turbo_stream: turbo_stream.replace(
      tag_preference,
      partial: 'form',
      locals: { tag: tag_preference.tag, tag_preference: tag_preference }
    )
  end

  private

  def tag_preference_params
    params.require(:tag_preference).permit(
      :enabled, 
      :is_allowed_third_party_tag, 
      :is_third_party_tag, 
      :should_log_tag_checks, 
      :consider_query_param_changes_new_tag, 
      :throttle_minute_threshold
    )
  end
end