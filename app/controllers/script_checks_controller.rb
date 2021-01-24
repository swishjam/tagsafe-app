class ScriptChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .is_third_party_tag
                                            .still_on_site
                                            .order('scripts.should_log_script_checks')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end