class LoggedInController < ApplicationController
  layout 'logged_in_layout'

  before_action :ensure_domain
  # before_action :ensure_subscription_plan
  before_action :set_current_domain_and_redirect_if_param_present

  def authorize!
    if current_user.nil?
      log_user_out
      session[:redirect_url] = request.original_url
      redirect_to domain_registrations_path 
    end
  end

  def ensure_domain
    redirect_to current_user.nil? ? domain_registrations_path : new_domain_path if current_domain.nil?
  end

  def ensure_subscription_plan
    redirect_to select_subscription_plans_path unless current_domain.has_current_subscription_plan?
  end

  def set_current_domain_and_redirect_if_param_present
    unless params[:_domain_uid].nil? || current_user.nil?
      domain = current_user.domains.find_by!(uid: params[:_domain_uid])
      set_current_domain(domain)
      redirect_to request.path
    end
  end
end