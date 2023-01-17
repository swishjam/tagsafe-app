class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  before_action :authorize!
  before_action :find_and_validate_container
  before_action :check_for_install_banner

  def authorize!
    if current_user.nil?
      log_user_out
      session[:redirect_url] = request.original_url
      redirect_to new_registration_path 
    end
  end

  def find_and_validate_container
    @container = current_user.containers.find_by!(uid: params[:container_uid])
  # rescue ActiveRecord::RecordNotFound => e
    # redirect_to root_path
  end

  def check_for_install_banner
    @display_install_banner = @container && @container.page_loads.none?
  end
end