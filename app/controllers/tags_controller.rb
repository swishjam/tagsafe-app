class TagsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Tags')
    @navigation_items = [
      { url: root_path, text: 'Tags' },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    ]
  end

  def show
    @tag = current_container.tags.includes(:tag_identifying_data).find_by(uid: params[:uid])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { text: 'Tags', url: root_path },
      { text: "#{@tag.try_friendly_name} Details" }
    )
  end

  def edit
    @tag = current_container.tags.find_by!(uid: params[:uid])
    stream_modal(
      partial: 'tags/edit',
      locals: { tag: @tag }
    )
  end

  def update
    @tag = current_container.tags.find_by(uid: params[:uid])
    @tag.update!(tag_params)
    render turbo_stream: turbo_stream.replace(
      "#{@tag.uid}_settings",
      partial: 'tags/form',
      locals: { tag: @tag, success_message: "#{@tag.try_friendly_name} updated successfully."}
    )
  end

  def select_tag_to_audit
    tags = current_container.tags.includes(:tag_identifying_data).order('tag_identifying_data.name, tags.url_hostname')
    stream_modal(partial: "tags/select_tag_to_audit", locals: { tags: tags })
  end

  def uptime
    @tag = current_container.tags.find_by(uid: params[:uid])
    render_breadcrumbs(
      { text: 'Monitor Center', url: root_path }, 
      { text: "#{@tag.try_friendly_name} Uptime", active: true }
    )
  end

  def uptime_metrics
    tag = current_container.tags.find_by(uid: params[:uid])
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
    @tag = current_container.tags.find_by(uid: params[:uid])
    @audits = @tag.audits.most_recent_first(timestamp_column: :created_at).page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { url: root_path, text: 'Monitor Center' },
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
