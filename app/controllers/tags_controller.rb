class TagsController < LoggedInController
  def show
    @tag = current_domain.tags.find(params[:id])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", active: true }
    )
  end

  def edit
    @tag = current_domain.tags.find(params[:id])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def audit_settings
    @tag = current_domain.tags.find(params[:tag_id])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def notification_settings
    @tag = current_domain.tags.find(params[:tag_id])
    if current_organization.completed_slack_setup?
      @slack_channels_options = current_organization.slack_client.get_channels['channels'].map { |channel| channel['name'] }
    end
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def update
    tag = Tag.find(params[:id])
    permitted_to_view?(tag, raise_error: true)
    params[:tag][:friendly_name] = params[:tag][:friendly_name].empty? ? nil : params[:tag][:friendly_name]
    params[:tag][:tag_preferences_attributes][:id] = tag.tag_preferences.id
    if tag.update(tag_params)
      # if tag.saved_changes.any?
        current_user.broadcast_notification("#{tag.try_friendly_name} updated.", image: tag.try_image_url)
      # end
    else
      current_user.broadcast_notification(tag.errors.full_sentences.join('\n'), image: tag.try_image_url)
    end
    render turbo_stream: turbo_stream.replace(
      "#{tag.id}_edit_general_settings",
      partial: 'edit_general_settings',
      locals: { tag: tag }
    )
  end

  private

  def tag_params
    params.require(:tag).permit(:friendly_name, :image, tag_preferences_attributes: tag_preference_attributes)
  end

  def tag_preference_attributes
    attrs = %i[id monitor_changes consider_query_param_changes_new_tag page_url_to_perform_audit_on]
    attrs << should_run_audit if ENV['SHOULD_RUN_AUDIT_IS_TOGGLABLE'] == 'true'
    attrs
  end
end