class TagsController < LoggedInController
  # def index
  #   unless current_domain.nil?
  #     @tags = current_domain.tags.joins(:tag_preferences)
  #                             .order('tag_preferences.should_run_audit DESC')
  #                             .order('removed_from_site_at ASC')
  #                             .order('content_changed_at DESC')
  #                             .page(params[:page] || 1).per(params[:per_page] || 9)
  #     @active_tag_count = current_domain.tags.is_third_party_tag.still_on_site.count
  #     @domain_scan = current_domain.domain_scans&.most_recent
  #   end
  # end

  def show
    @tag = current_domain.tags.find(params[:id])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    permitted_to_view?(@tag)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", active: true }
    )
  end

  def edit
    @tag = Tag.find(params[:id])
    permitted_to_view?(@tag)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def notification_settings
    @tag = Tag.find(params[:tag_id])
    permitted_to_view?(@tag)
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
        current_user.broadcast_notification("#{tag.try_friendly_name} updated.", tag.try_image_url)
      # end
    else
      current_user.broadcast_notification(tag.errors.full_sentences.join('\n'), tag.try_image_url)
    end
    render turbo_stream: turbo_stream.replace(
      "#{tag.id}_edit_general_settings",
      partial: 'edit_general_settings',
      locals: { tag: tag }
    )
  end

  private

  def tag_params
    params.require(:tag).permit(:friendly_name, :image, 
                                tag_preferences_attributes: %i[
                                  id
                                  should_run_audit 
                                  url_to_audit 
                                  num_test_iterations 
                                  monitor_changes 
                                  is_allowed_third_party_tag 
                                  is_third_party_tag
                                  should_log_tag_checks 
                                  consider_query_param_changes_new_tag 
                                  throttle_minute_threshold
                                ])
  end
end