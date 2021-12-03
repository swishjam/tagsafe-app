class DomainsController < LoggedInController
  skip_before_action :ensure_domain

  def new
    @domain = Domain.new
    @collapsed_navigation = true
  end
  
  def create
    params[:domain][:organization_id] = current_organization.id
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    @domain = Domain.new(domain_params)
    if @domain.save
      set_current_domain_for_user(current_user, @domain)
      redirect_to tags_path
    else
      display_inline_errors(@domain.errors.full_messages)
      render :new, status: :unprocessable_entity
    end
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
    domain = Domain.find_by!(uid: params[:uid])
    set_current_domain_for_user(current_user, domain)
    redirect_to tags_path
  end

  def crawl
    domain = Domain.find(params[:id])
    raise StandardError, 'No permission' unless domain.user_can_initiate_crawl?(current_user)
    if domain.urls_to_crawl.any?
      domain.crawl_and_capture_domains_tags
      current_user.broadcast_notification('Crawling for third party tags...')
    else
      current_user.broadcast_notification('No URLs to crawl defined', error: true)
    end
    head :no_content
  end

  private

  def domain_params
    params.require(:domain).permit(:url, :organization_id)
  end
end