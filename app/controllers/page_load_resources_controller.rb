class PageLoadResourcesController < LoggedInController
  def index
    tag = current_domain.tags.find(params[:tag_id])
    audit = tag.audits.find(params[:audit_id])
    
    raise StandardError, 'Must pass `performance_audit_type` URL parameter' if params[:performance_audit_type].nil?
    perf_audit_getter_method = params[:performance_audit_type] == 'with_tag' ? :performance_audit_with_tag_used_for_scoring : :performance_audit_without_tag_used_for_scoring
    perf_audit = audit.send(perf_audit_getter_method)
    
    resources = perf_audit.page_load_resources.display_for_waterfall.order(fetch_start: :ASC)
    last_timestamp = resources.last.response_end
    
    render turbo_stream: turbo_stream.replace(
      "page_load_resources_#{params[:performance_audit_type]}",
      partial: 'page_load_resources/index',
      locals: {
        tag: tag,
        performance_audit: perf_audit,
        audited_tag_version_url: audit.tag_version.hosted_tagsafe_instrumented_js_file_url(false),
        performance_audit_type: params[:performance_audit_type],
        page_load_resources: resources, 
        last_timestamp: last_timestamp
      }
    )
  end
end