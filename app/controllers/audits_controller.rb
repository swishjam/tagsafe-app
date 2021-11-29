class AuditsController < LoggedInController
  def index
    @tag = current_domain.tags.find(params[:tag_id])
    @tag_version = TagVersion.find(params[:tag_version_id])
    @audits = @tag_version.audits.most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
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
    audit = Audit.find(params[:id])
    permitted_to_view?(audit)
    audit.make_primary!
    current_user.broadcast_notification('Primary audit updated')
    render turbo_stream: turbo_stream.replace(
      "#{audit.tag_id}_tag_version_audits",
      partial: 'audit', collection: audit.tag_version.audits.most_recent_first.includes(:performance_audits), as: :audit
    )
  end

  def cloudwatch_logs
    @hide_navigation = true
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