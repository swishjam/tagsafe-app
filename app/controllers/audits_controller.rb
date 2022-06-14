class AuditsController < LoggedInController
  SHOW_VIEWS = %i[show performance_audit test_runs test_run page_change_audit waterfall git_diff]
  before_action :find_tag, except: :all
  before_action :find_audit, except: %i[all index new create]
  before_action :render_breadcrumbs_for_show_views, only: SHOW_VIEWS

  def all
    @audits = current_domain.audits
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
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
    )
  end

  def show
    redirect_to performance_audit_tag_audit_path(params[:tag_uid], params[:uid])
  end

  def new
    tag_version = if params[:tag_version_uid]
                    @tag.tag_versions.find_by(uid: params[:tag_version_uid])
                  else
                    @tag.release_monitoring_enabled? ? @tag.current_version : nil 
                  end
    urls_to_audit = @tag.urls_to_audit.includes(:page_url)
    stream_modal(partial: 'audits/new', locals: { 
      tag: @tag, 
      tag_version: tag_version,
      feature_prices: current_domain.feature_prices_in_credits,
      current_tag_version: @tag.current_version,
      urls_to_audit: urls_to_audit,
      configuration: @tag.tag_or_domain_configuration
    })
  end

  def create
    tag_version = @tag.tag_versions.find_by(uid: params[:tag_version_uid])
    audits_enqueued = []
    audits_with_errors = []
    @tag.urls_to_audit.where(id: params[:urls_to_audit]).each do |url_to_audit|
      audit = @tag.perform_audit!(
        initiated_by_domain_user: current_domain_user,
        execution_reason: ExecutionReason.MANUAL,
        url_to_audit: url_to_audit,
        tag_version: tag_version, 
        options: {
          include_performance_audit: params.dig(:config, :include_performance_audit) == 'true',
          # include_page_change_audit: params.dig(:config, :include_page_change_audit) == 'true',
          include_functional_tests: params.dig(:config, :include_functional_tests) == 'true',
          include_page_load_resources: params.dig(:config, :include_page_load_resources) == 'true',
          performance_audit_configuration: {
            # include_page_tracing: params.dig(:config, :performance_audit_settings, :include_page_trace) == 'true',
            include_filmstrip_frames: params.dig(:config, :performance_audit_settings, :include_filmstrip_frames) == 'true',
            strip_all_images: params.dig(:config, :performance_audit_settings, :strip_all_images) == 'true',
            enable_screen_recording: params.dig(:config, :performance_audit_settings, :enable_screen_recording) == 'true',
            throw_error_if_dom_complete_is_zero: true,
            inline_injected_script_tags: false
          }
        }
      )
      (audit.errors.any? ? audits_with_errors : audits_enqueued) << audit
    end
    current_user.broadcast_notification(message: "Performing audit on #{@tag.try_friendly_name}", image: @tag.try_image_url) unless audits_enqueued.empty? || user_is_anonymous?
    stream_modal(partial: 'audits/new', locals: { tag: @tag, tag_version: tag_version, audits_enqueued: audits_enqueued, audits_with_errors: audits_with_errors })
  end

  # def make_primary
  #   @audit.make_primary!
  #   current_user.broadcast_notification("Primary audit updated for #{@audit.tag.try_friendly_name} version #{audit.tag_version.sha}", image: audit.tag.try_image_url)
  #   updated_audits_collection = @audit.tag_version.audits.order(primary: :DESC).most_recent_first(timestamp_column: :enqueued_suite_at).includes(:performance_audits)
  #   render turbo_stream: turbo_stream.replace(
  #     "tag_version_#{@audit.tag_version.uid}_audits_table",
  #     partial: 'audits/audits_table',
  #     locals: { tag_version: @tag_version, audits: updated_audits_collection, streamed: true }
  #   )
  # end

  def cloudwatch_logs
    @performance_audits_with_tag = @audit.performance_audits_with_tag
    @performance_audits_without_tag = @audit.performance_audits_without_tag
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_audits_path(@tag), text: "#{@tag_version.sha} Audits" },
      { url: performance_audit_tag_audit_path(@tag, @audit),  text: "#{@audit.created_at.formatted_short} Audit" },
      { text: "#{@audit.created_at.formatted_short} Audit Cloudwatch logs", active: true },
    )
  end

  private

  def find_tag
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
  end

  def find_audit
    @audit = @tag.audits.find_by(uid: params[:uid])
  end

  def render_breadcrumbs_for_show_views
    render_breadcrumbs(
      { url: tags_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      # { url: tag_audits_path(@tag), text: "Version #{@tag_version.sha} audits" },
      { text: "#{@audit.created_at.formatted_short} audit", active: true }
    )
  end
end