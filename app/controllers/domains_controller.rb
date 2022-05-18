class DomainsController < LoggedOutController
  # skip_before_action :ensure_domain

  def new
    redirect_to select_subscription_plans_path if current_domain && params[:additional].nil?
    @domain = Domain.new
    @hide_logged_out_nav = true
    @hide_navigation = true
  end
  
  def create
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    params[:domain][:is_generating_third_party_impact_trial] = false
    @domain = Domain.new(domain_params)
    if @domain.save
      set_current_domain(@domain)
      if current_user.nil?
        redirect_to new_registration_path
      else
        current_user.domains << @domain
        Role.USER_ADMIN.apply_to_domain_user(current_user.domain_user_for(@domain))
        redirect_to tags_path
      end
    else
      display_inline_errors(@domain.errors.full_messages)
      @hide_navigation = true
      render :new, status: :unprocessable_entity
    end
  end

  def update
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    domain = Domain.find_by(uid: params[:uid])
    if domain.update(domain_params)
      domain.crawl_and_capture_domains_tags(true)
      display_toast_message("Scanning #{domain.url} for third party tags.")
    else
      display_toast_error(domain.errors.full_messages.join(' '))
    end
    redirect_to request.referrer
  end

  def update_current_domain
    # domain = Domain.find_by!(uid: params[:uid])
    domain = current_user.domains.find_by!(uid: params[:uid])
    set_current_domain(domain)
    redirect_to tags_path
  end
  
  private

  def domain_params
    params.require(:domain).permit(:url)
  end
end