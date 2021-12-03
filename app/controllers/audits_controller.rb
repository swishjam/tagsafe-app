class AuditsController < LoggedInController
  def index
    @tag = current_domain.tags.find(params[:tag_id])
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audits = @tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: "Version #{@tag_version.sha} audits", active: true }
    )
  end

  def show
    @tag = current_domain.tags.find(params[:tag_id])
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = Audit.find(params[:id])
    @previous_audit = @tag_version.previous_version&.primary_audit
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "Version #{@tag_version.sha} audits" },
      { text: "#{@audit.created_at.formatted_short} audit", active: true }
    )
  end

  def make_primary
    audit = Audit.includes(:tag, :tag_version).find(params[:id])
    permitted_to_view?(audit)
    audit.make_primary!
    current_user.broadcast_notification("Primary audit updated for #{audit.tag.try_friendly_name} version #{audit.tag_version.sha}", image: audit.tag.try_image_url)
    updated_audits_collection = audit.tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
    render turbo_stream: turbo_stream.replace(
      "tag_version_#{audit.tag_version.uid}_audits_table",
      partial: 'audits/audits_table',
      locals: { tag_version: audit.tag_version, audits: updated_audits_collection, streamed: true }
    )
  end

  def cloudwatch_logs
    @tag = Tag.find(params[:tag_id])
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audit = Audit.includes(:performance_audits).find(params[:audit_id])
    @performance_audits_with_tag = @audit.individual_performance_audits_with_tag
    @performance_audits_without_tag = @audit.individual_performance_audits_without_tag
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.created_at.formatted_short} Change Audits" },
      { url: tag_tag_version_audit_path(@tag, @tag_version, @audit),  text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "#{@audit.created_at.formatted_short} Audit Cloudwatch logs", active: true },
    )
  end
end