class TagsController < LoggedInController
  def index
    unless current_domain.nil?
      @tags = current_domain.tags
                              .order('should_run_audit DESC')
                              .order('removed_from_site_at ASC')
                              .order('content_changed_at DESC')
                              .page(params[:page] || 1).per(params[:per_page] || 9)
      @active_tag_count = current_domain.tags.is_third_party_tag.still_on_site.count
      @domain_scan = current_domain.domain_scans&.most_recent
    end
  end

  def show
    @tag = current_domain.tags.find(params[:id])
    @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
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
      { text: "Edit #{@tag.try_friendly_name}", active: true }
    )
  end

  def performance_audit_settings
    @tag = Tag.joins(:performance_audit_preferences).find(params[:tag_id])
    permitted_to_view?(@tag)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit #{@tag.try_friendly_name}", active: true }
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
      { text: "Edit #{@tag.try_friendly_name}", active: true }
    )
  end

  def update
    @tag = Tag.find(params[:id])
    permitted_to_view?(@tag, raise_error: true)
    params[:tag][:friendly_name] = params[:tag][:friendly_name].empty? ? nil : params[:tag][:friendly_name]
    if @tag.update(tag_params)
      display_toast_message("Successfully updated #{@tag.try_friendly_name}")
    else
      display_toast_error(@tag.errors.full_messages.join('\n'))
    end
    redirect_to request.referrer
  end

  private

  def tag_params
    params.require(:tag).permit(:friendly_name, :throttle_minute_threshold, :monitor_changes, :is_third_party_tag, :allowed_third_party_tag, :should_run_audit, :image)
  end
end