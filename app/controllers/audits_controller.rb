class AuditsController < LoggedInController
  before_action :find_tag_and_tag_version
  before_action :find_audit, except: :index
  before_action :render_breadcrumbs_for_show_views, only: [:show, :performance_audit, :functional_tests, :page_change_audit, :waterfall, :git_diff]

  def index
    @audits = @tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { text: "Version #{@tag_version.sha} audits", active: true }
    )
  end

  def make_primary
    @audit.make_primary!
    current_user.broadcast_notification("Primary audit updated for #{@audit.tag.try_friendly_name} version #{audit.tag_version.sha}", image: audit.tag.try_image_url)
    updated_audits_collection = @audit.tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_at).includes(:performance_audits)
    render turbo_stream: turbo_stream.replace(
      "tag_version_#{@audit.tag_version.uid}_audits_table",
      partial: 'audits/audits_table',
      locals: { tag_version: @tag_version, audits: updated_audits_collection, streamed: true }
    )
  end

  def cloudwatch_logs
    @performance_audits_with_tag = @audit.individual_performance_audits_with_tag
    @performance_audits_without_tag = @audit.individual_performance_audits_without_tag
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "#{@tag_version.sha} Audits" },
      { url: performance_audit_tag_tag_version_audit_path(@tag, @tag_version, @audit),  text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "#{@audit.created_at.formatted_short} Audit Cloudwatch logs", active: true },
    )
  end

  private

  def find_tag_and_tag_version
    @tag = current_domain.tags.find(params[:tag_id])
    @tag_version = @tag.tag_versions.find(params[:tag_version_id])
  end

  def find_audit
    @audit = @tag_version.audits.find(params[:id])
  end

  def render_breadcrumbs_for_show_views
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} details" },
      { url: tag_tag_version_audits_path(@tag, @tag_version), text: "Version #{@tag_version.sha} audits" },
      { text: "#{@audit.created_at.formatted_short} audit", active: true }
    )
  end
end