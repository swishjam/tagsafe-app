class ScriptChecksController < LoggedInController
  def index
    @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('scripts.should_log_script_checks')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end