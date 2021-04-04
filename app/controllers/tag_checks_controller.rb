class TagChecksController < LoggedInController
  def index
    @days_ago = (params[:days_ago] || 7).to_i
    @tags = current_domain.tags
                                            .available_for_uptime
                                            .order('content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end