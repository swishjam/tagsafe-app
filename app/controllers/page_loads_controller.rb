class PageLoadsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Performance' }
    )
    render_default_navigation_items(:settings)
  end
end
