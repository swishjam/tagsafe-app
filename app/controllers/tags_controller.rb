class TagsController < LoggedInController
  def show
    @tag = current_domain.tags.find(params[:id])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", active: true }
    )
  end

  def uptime
    @tag = current_domain.tags.find(params[:id])
  end

  def edit
    @tag = current_domain.tags.find(params[:id])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def audits
    tag = current_domain.tags.find(params[:id])
    audits = tag.audits.most_recent_first(timestamp_column: :created_at)
                        .includes(:performance_audits)
                        .page(params[:page] || 1)
                        .per(params[:per_page] || 10)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_audits_table",
      partial: "tags/audits",
      locals: {
        tag: tag,
        audits: audits
      }
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
    if current_domain.completed_slack_setup?
      @slack_channels_options = current_domain.slack_client.get_channels['channels'].map { |channel| channel['name'] }
    end
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def update
    tag = current_domain.tags.find(params[:id])
    params[:tag][:friendly_name] = params[:tag][:friendly_name].empty? ? nil : params[:tag][:friendly_name]
    params[:tag][:tag_preferences_attributes][:id] = tag.tag_preferences.id
    if tag.update(tag_params)
      # if tag.saved_changes.any?
        current_user.broadcast_notification(message: "#{tag.try_friendly_name} updated.", image: tag.try_image_url)
      # end
    else
      current_user.broadcast_notification(message: tag.errors.full_sentences.join('\n'), image: tag.try_image_url)
    end
    render turbo_stream: turbo_stream.replace(
      "#{tag.id}_edit_general_settings",
      partial: 'edit_general_settings',
      locals: { tag: tag }
    )
  end

  def enable
    @tag = current_domain.tags.find(params[:id])
    @tag.tag_preferences.update!(enabled: true) unless @tag.release_monitoring_enabled?
    current_user.broadcast_notification(message: "Tag monitoring is now enabled for #{@tag.try_friendly_name}", image: @tag.try_image_url)
    render :edit
    # render turbo_stream: turbo_stream.replace(
    #   "#{tag.id}_edit_general_settings",
    #   partial: 'edit_general_settings',
    #   locals: { tag: tag }
    # )
  end

  def disable
    @tag = current_domain.tags.find(params[:id])
    @tag.tag_preferences.update!(enabled: false) unless @tag.disabled?
    current_user.broadcast_notification(message: "Tag monitoring is now disabled for #{@tag.try_friendly_name}", image: @tag.try_image_url)
    render :edit
    # render turbo_stream: turbo_stream.replace(
    #   "#{tag.id}_edit_general_settings",
    #   partial: 'edit_general_settings',
    #   locals: { tag: tag }
    # )
  end

  private

  def tag_params
    params.require(:tag).permit(:friendly_name, :image, tag_preferences_attributes: %i[id enabled consider_query_param_changes_new_tag])
  end
end