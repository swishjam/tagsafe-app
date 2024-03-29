class TagsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Tags')
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Containers' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings' },
    )
  end

  def show
    @tag = @container.tags.includes(:tag_identifying_data).find_by(uid: params[:uid])
    render_breadcrumbs(
      { text: 'Tags', url: container_tag_snippets_path(@container) },
      { text: "#{@tag.try_friendly_name} Details" }
    )
  end

  def edit
    @tag = @container.tags.find_by!(uid: params[:uid])
    stream_modal(
      partial: 'tags/edit',
      locals: { 
        tag: @tag,
        tag_snippet: @tag.tag_snippet,
        container: @container,
      }
    )
  end

  def update
    @tag = @container.tags.find_by(uid: params[:uid])
    if @tag.update(tag_params)
      render turbo_stream: turbo_stream.replace(
        "#{@tag.uid}_settings",
        partial: 'tags/form',
        locals: { 
          tag: @tag, 
          tag_snippet: @tag.tag_snippet,
          container: @container,
          success_message: "#{@tag.try_friendly_name} updated successfully.",
        }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "#{@tag.uid}_settings",
        partial: 'tags/form',
        locals: {
          tag: @tag,
          tag_snippet: @tag.tag_snippet,
          container: @container,
          error_message: @tag.errors.full_messages.join(', '),
        }
      )
    end
  end

  def select_tag_to_audit
    tags = @container.tags.includes(:tag_identifying_data).order('tag_identifying_data.name, tags.url_hostname')
    stream_modal(partial: "tags/select_tag_to_audit", locals: { tags: tags })
  end

  def uptime
    @tag = @container.tags.find_by(uid: params[:uid])
    render_breadcrumbs(
      { text: 'Monitor Center', url: container_tag_snippets_path(@container) }, 
      { text: "#{@tag.try_friendly_name} Uptime", active: true }
    )
  end

  def uptime_metrics
    tag = @container.tags.find_by(uid: params[:uid])
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

  def audits
    @tag = @container.tags.find_by(uid: params[:uid])
    @audits = @tag.audits.most_recent_first(timestamp_column: :created_at).page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { url: container_tag_snippets_path(@container), text: 'Monitor Center' },
      { text: "#{@tag.try_friendly_name} audits" }
    )
    respond_to do |format|
      format.html { render 'audits' }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "tag_#{@tag.uid}_audits_table",
          partial: "tags/audits",
          locals: {
            tag: @tag,
            audits: @audits
          }
        )
      }
    end
  end

  private

  def tag_params
    params.require(:tag).permit(:release_monitoring_interval_in_minutes, :is_tagsafe_hosted, :configured_load_type)
  end
end
