class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  # before_action :authorize!
  before_action :ensure_domain
  before_action :ensure_subscription_plan

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

  def ensure_subscription_plan
    redirect_to select_subscription_plans_path unless current_domain.has_current_subscription_plan?
  end
end