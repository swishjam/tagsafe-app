class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  # before_action :authorize!
  before_action :ensure_domain

  def authorize!
    if current_user.nil?
      log_user_out
      session[:redirect_url] = request.original_url
      redirect_to login_path 
    end
  end

  def ensure_domain
    redirect_to new_domain_path if current_domain.nil?
  end
end