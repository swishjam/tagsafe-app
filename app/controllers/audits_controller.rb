class AuditsController < LoggedInController
  SHOW_VIEWS = %i[show performance_audit test_runs test_run waterfall git_diff]
  before_action :find_tag, except: :all
  before_action :find_audit, except: %i[all index new create]
  before_action :render_breadcrumbs_for_show_views, only: SHOW_VIEWS

  def all
    @audits = @container.audits
                              .most_recent_first(timestamp_column: :created_at)
                              .includes(
                                :performance_audits, 
                                :delta_performance_audits, 
                                :test_runs
                              )
                              .page(params[:page] || 1)
                              .per(params[:per_page] || 10)
    render_breadcrumbs(text: 'Audit Log')
  end

  def index
    @audits = @tag.audits.order(primary: :DESC)
                            .most_recent_first(timestamp_column: :created_at)
                            .includes(:performance_audits)
                            .page(params[:page] || 1)
                            .per(params[:per_page] || 20)
    render_breadcrumbs(
      { url: container_tag_snippets_path(@container), text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
    )
  end

  def show
    # redirect_to performance_audit_tag_audit_path(params[:tag_uid], params[:uid])
  end

  def new
    tag_version = @tag.current_live_tag_version
    stream_modal(partial: 'audits/new', locals: { 
      tag: @tag, 
      tag_version: tag_version,
      page_urls: @container.page_urls,
    })
  end

  def create
    tag_version = @tag.tag_versions.find_by(uid: params[:tag_version_uid])
    audits_enqueued = []
    audits_with_errors = []
    params[:page_url_uids_to_audit].each do |page_url_uid|
      page_url = @container.page_urls.find_by!(uid: page_url_uid)
      audit = Audit.run(
        tag: @tag,
        tag_version: tag_version,
        page_url: page_url,
        execution_reason: ExecutionReason.MANUAL,
        initiated_by_container_user: @container_user,
      )
      (audit.errors.any? ? audits_with_errors : audits_enqueued) << audit
    end
    stream_modal(partial: 'audits/new', locals: {
      tag: @tag,
      tag_version: tag_version,
      audits_enqueued: audits_enqueued,
      audits_with_errors: audits_with_errors,
    })
  end

  private

  def find_tag
    @tag = @container.tags.find_by(uid: params[:tag_uid])
  end

  def find_audit
    @audit = @tag.audits.find_by(uid: params[:uid])
  end

  def render_breadcrumbs_for_show_views
    render_breadcrumbs(
      { url: container_tag_snippets_path(@container), text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      # { url: tag_audits_path(@tag), text: "Version #{@tag_version.sha} audits" },
      { text: "#{@audit.created_at.formatted_short} audit", active: true }
    )
  end
end