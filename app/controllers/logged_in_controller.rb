class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  before_action :ensure_container
  before_action :check_for_install_banner

  def authorize!
    if current_user.nil?
      log_user_out
      session[:redirect_url] = request.original_url
      redirect_to new_registration_path 
    end
  end

  def ensure_container
    return true if current_container.present?
    redirect_to current_user.nil? ? new_registration_path : new_container_path
  end

  def check_for_install_banner
    return if current_container.nil?
    # @display_install_banner = current_container.page_loads.none?
    @display_install_banner = true
  end
end