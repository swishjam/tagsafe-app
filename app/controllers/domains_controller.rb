class DomainsController < LoggedInController
  skip_before_action :ensure_domain

  def new
    @hide_navigation = true
  end
  
  def create
    params[:domain][:organization_id] = current_organization.id
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    domain = Domain.create(domain_params)
    if domain.valid?
      display_toast_message("Scanning #{domain.url} for third party tags.")
    else
      display_toast_error(domain.errors.full_messages.join(' '))
    end
    redirect_to request.referrer
  end

  def update
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    domain = Domain.find(params[:id])
    if domain.update(domain_params)
      domain.crawl_and_capture_domains_tags(true)
      display_toast_message("Scanning #{domain.url} for third party tags.")
    else
      display_toast_error(domain.errors.full_messages.join(' '))
    end
    redirect_to request.referrer
  end

  def update_current_domain
    domain = Domain.find(params[:id])
    session[:current_domain_id] = domain.id
    flash[:notice] = "Domain updated to #{domain.url}"
    redirect_to tags_path
  end

  def scan
    domain = Domain.find(params[:id])
    raise StandardError, 'No permission' unless domain.user_can_initiate_crawl?(current_user)
    domain.crawl_and_capture_domains_tags
    current_user.broadcast_notification('Domain scan in progress')
    head :no_content
    # render turbo_stream: turbo_stream
    # redirect_to request.referrer
  end

  private

  def domain_params
    params.require(:domain).permit(:url, :organization_id)
  end
end