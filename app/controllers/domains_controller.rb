class DomainsController < LoggedInController
  skip_before_action :ensure_domain

  def new
    @domain = Domain.new
    if current_domain.nil?
      # if user got into a weird state
      @hide_navigation = true
    else
      @collapsed_navigation = true
    end
  end
  
  def create
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    params[:domain][:is_generating_third_party_impact_trial] = false
    @domain = Domain.new(domain_params)
    if @domain.save
      current_user.domains << @domain
      set_current_domain(@domain)
      Role.USER_ADMIN.apply_to_domain_user(current_user.domain_user_for(@domain))
      redirect_to tags_path
    else
      display_inline_errors(@domain.errors.full_messages)
      @hide_navigation = true
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
    set_current_domain(domain)
    redirect_to tags_path
  end

  # def crawl
  #   domain = Domain.find(params[:id])
  #   raise StandardError, 'No permission' unless domain.user_can_initiate_crawl?(current_user)
  #   domain.crawl_and_capture_domains_tags
  #   current_user.broadcast_notification(message: "Syncing #{domain.url}'s third party tags...")
  #   head :no_content
  # end

  private

  def domain_params
    params.require(:domain).permit(:url)
  end
end