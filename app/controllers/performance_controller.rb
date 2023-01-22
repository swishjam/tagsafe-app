class PerformanceController < LoggedInController
  def index
    @tags = @container.tags
                            .order('removed_from_site_at ASC')
                            .order('last_released_at DESC')
                            .page(params[:page] || 1).per(params[:per_page] || 9)
    render_breadcrumbs(text: 'Tag Performance')
  end
end