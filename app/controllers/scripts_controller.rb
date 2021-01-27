class ScriptsController < LoggedInController
  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('script_subscribers.should_run_audit DESC')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
      @active_tag_count = current_domain.script_subscriptions.is_third_party_tag.still_on_site.count
      @domain_scan = current_domain.domain_scans&.most_recent
    end
  end
end