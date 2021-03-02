class ScriptChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .available_for_uptime
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end