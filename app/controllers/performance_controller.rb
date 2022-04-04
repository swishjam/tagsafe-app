class PerformanceController < LoggedInController
  def index
    @tags = current_domain.tags
                            .is_third_party_tag
                            .order('removed_from_site_at ASC')
                            .order('last_released_at DESC')
                            .page(params[:page] || 1).per(params[:per_page] || 9)
  end
end