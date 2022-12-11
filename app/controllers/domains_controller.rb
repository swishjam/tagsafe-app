class DomainsController < LoggedInController
  skip_before_action :ensure_domain, only: [:new, :create]

  def install_script
    stream_modal(locals: { instrumentation_key: current_domain.instrumentation_key })
  end

  def new
    @domain = Domain.new
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

  def update_current_domain
    # domain = Domain.find_by!(uid: params[:uid])
    domain = current_user.domains.find_by!(uid: params[:uid])
    set_current_domain(domain)
    redirect_to request.referrer
  end
  
  private

  def domain_params
    params.require(:domain).permit(:url)
  end
end