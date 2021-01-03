class ScriptsController < LoggedInController
  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('script_subscribers.should_run_audits DESC')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
      @filtered_performance_audit_metric_type = PerformanceAuditMetricType.find_by(key: params[:metric_type] || 'TagSafeScore')
      @active_tag_count = current_domain.script_subscriptions.is_third_party_tag.still_on_site.count
      @most_recent_domain_scan_pending = current_domain.domain_scans&.most_recent&.pending?
      @most_recent_domain_scan_failed = current_domain.domain_scans&.most_recent&.failed?
    end
  end
end