class PageLoadResourcesController < LoggedInController
  def for_audit
    @tag = current_container.tags.find_by(uid: params[:tag_uid])
    @tag_version = TagVersion.find_by(uid: params[:tag_version_uid])
    @audit = Audit.find_by(uid: params[:audit_uid])
    render_breadcrumbs(
      { url: root_path, text: "Monitor Center" },
      { url: tag_path(@tag), text: "#{@tag.try_friendly_name} Details" },
      { url: tag_audits_path(@tag), text: "#{@tag_version.sha} Audits" },
      { text: "#{@audit.created_at.formatted_short} Waterfall Chart", active: true },
    )
  end

  def index
    tag = current_container.tags.find_by(uid: params[:tag_uid])
    audit = tag.audits.find_by(uid: params[:audit_uid])
    
    raise StandardError, 'Must pass `performance_audit_type` URL parameter' if params[:performance_audit_type].nil?
    perf_audit_getter_method = params[:performance_audit_type] == 'with_tag' ? :median_individual_performance_audit_with_tag : :median_individual_performance_audit_without_tag
    perf_audit = audit.send(perf_audit_getter_method)
    
    resources = perf_audit.page_load_resources.display_for_waterfall.order(fetch_start: :ASC)
    last_timestamp = [
      perf_audit.dom_complete,
      perf_audit.dom_interactive, 
      perf_audit.first_contentful_paint,
      perf_audit.script_duration,
      perf_audit.layout_duration,
      perf_audit.task_duration,
      perf_audit.page_load_resources.display_for_waterfall.order(response_end: :DESC).limit(1).first.response_end
    ].max + 50

    blocked_resources = perf_audit.blocked_resources
    
    render turbo_stream: turbo_stream.replace(
      "page_load_resources_#{params[:performance_audit_type]}",
      partial: 'page_load_resources/index',
      locals: {
        tag: tag,
        title: "Waterfall #{params[:performance_audit_type] == 'with_tag' ? 'with' : 'without'} tag",
        performance_audit: perf_audit,
        audited_tag_version_url: audit.ran_on_live_tag? ? tag.url_based_on_preferences : audit.tag_version.js_file_url,
        performance_audit_type: params[:performance_audit_type],
        page_load_resources: resources, 
        blocked_resources: blocked_resources,
        last_timestamp: last_timestamp
      }
    )
  end
end