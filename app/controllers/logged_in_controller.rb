class LoggedInController < ApplicationController
  before_action :authorize!
  before_action :ensure_organization
  before_action :ensure_domain

  layout 'logged_in_layout'

  def authorize!
    if current_user.nil?
      display_toast_error("Please login.")
      session[:redirect_url] = request.original_url
      redirect_to login_path 
    end
  end

  def ensure_organization
    redirect_to new_organization_path if current_organization.nil?
  end

  def ensure_domain
    redirect_to new_domain_path if current_domain.nil?
  end
end