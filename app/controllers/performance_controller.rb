class PerformanceController < LoggedInController
  def index
    @tags = current_domain.tags
                            .is_third_party_tag
                            .order('should_run_audit DESC')
                            .order('monitor_changes DESC')
                            .order('removed_from_site_at ASC')
                            .order('content_changed_at DESC')
                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end