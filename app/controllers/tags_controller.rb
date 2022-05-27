class TagsController < LoggedInController
  def index
    render_breadcrumbs({ text: 'Monitor Center', active: true })
  end

  def show
    @tag = current_domain.tags.find_by(uid: params[:uid])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Audit Details", active: true }
    )
  end

  def select_tag_to_audit
    tags = current_domain.tags.includes(:tag_identifying_data, :tag_preferences).order('tag_identifying_data.name, tags.url_domain')
    stream_modal(partial: "tags/select_tag_to_audit", locals: { tags: tags })
  end

  def uptime
    @tag = current_domain.tags.find_by(uid: params[:uid])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Uptime", active: true }
    )
  end

  def uptime_metrics
    tag = current_domain.tags.find_by(uid: params[:uid])
    average_response_ms = tag.average_response_time
    max_response_ms = tag.max_response_time
    failed_requests = tag.num_failed_requests
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_uptime_metrics",
      partial: 'tags/uptime_metrics',
      locals: {
        tag: tag,
        average_response_ms: average_response_ms,
        max_response_ms: max_response_ms,
        failed_requests: failed_requests
      }
    )
  end

  def edit
    @tag = current_domain.tags.find_by(uid: params[:uid])
    @selectable_uptime_regions = UptimeRegion.selectable.not_enabled_on_tag(@tag)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def audits
    tag = current_domain.tags.find_by(uid: params[:uid])
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
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Details", url: tag_path(@tag) },
      { text: "Edit", active: true }
    )
  end

  def notification_settings
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
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
    tag = current_domain.tags.find_by(uid: params[:uid])
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

  private

  def tag_params
    params.require(:tag).permit(:friendly_name, :image, tag_preferences_attributes: %i[id enabled consider_query_param_changes_new_tag])
  end
end