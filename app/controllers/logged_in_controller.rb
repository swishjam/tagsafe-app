class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  before_action :ensure_container
  before_action :set_current_container_and_redirect_if_param_present

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

  def set_current_container_and_redirect_if_param_present
    unless params[:_container_uid].nil? || current_user.nil?
      container = current_user.containers.find_by!(uid: params[:_container_uid])
      set_current_container(container)
      redirect_to request.path
    end
  end
end