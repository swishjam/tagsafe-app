class TagsController < LoggedInController
  def index
    render_breadcrumbs({ text: 'Monitor Center', active: true })
  end

  def tag_manager
    @tags = current_domain.tags.page(params[:page] || 1).per(20)
    render_breadcrumbs(text: 'Tag Management')
  end

  def new
    @tag = current_domain.tags.new
    render_breadcrumbs(
      { text: 'Tag Management', url: tag_manager_path },
      { text: 'New Tag' }
    )
  end

  def create
    @tag = current_domain.tags.new(tag_params)
    
    if tag_params[:full_url].blank?
      local_file_name = "#{Time.now.to_i}-#{(rand() * 100_000_000).to_i}-script.js"
      local_file = File.open(Rails.root.join('tmp', local_file_name), "w") 
      local_file.puts(params[:tag][:js_script].force_encoding('UTF-8'))
      local_file.close
      @tag.js_script = { 
        io: File.open(local_file), 
        filename: local_file_name,
        content_type: 'text/javascript'
      }
      # File.delete(local_file)
    end

    if @tag.save
      redirect_to new_tag_tag_configuration_path(@tag)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def promote
    tags = current_domain.tags.where(uid: params[:tag_uids_to_promote])
    TagManager::Promoter.promote_staged_changes(tags)
    # need to think about the user experience for moving this to a background job
    # the banner will still be present because of the staged changes
    # PromoteTagsJob.perform_later(tags)
    redirect_to tag_manager_path
  end

  def show
    @tag = current_domain.tags.includes(:tag_identifying_data).find_by(uid: params[:uid])
    # @tag_versions = @tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
    render_breadcrumbs(
      { text: 'Monitor Center', url: tags_path }, 
      { text: "#{@tag.try_friendly_name} Audit Details", active: true }
    )
  end

  def select_tag_to_audit
    tags = current_domain.tags.includes(:tag_identifying_data, :draft_tag_configurations).order('tag_identifying_data.name, tags.url_domain')
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
    @tag = current_domain.tags.includes(:tag_identifying_data).find_by(uid: params[:uid])
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

  def update
    tag = current_domain.tags.find_by(uid: params[:uid])
    tag.update!(tag_params)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_config_fields",
      partial: "tags/config_fields",
      locals: {
        domain: current_domain,
        tag: tag,
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
        notification_message: "Updated #{tag.try_friendly_name}."
      }
    )
  end

  def toggle_disable
    tag = current_domain.tags.find_by(uid: params[:uid])
    tag.update!(script_inject_is_disabled: !tag.script_inject_is_disabled)
    redirect_to request.referrer
  end

  private

  def tag_params
    params.require(:tag).permit(:full_url, :name)
  end
end