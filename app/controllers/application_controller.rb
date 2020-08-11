class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :current_organization

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def current_organization
    @current_organization ||= current_user && current_user.organization
  end

  def authorize!
    if current_user.nil?
      flash[:error] = "Please login."
      redirect_to login_path 
    end
  end

  def ensure_logged_out
    redirect_to monitored_scripts_path unless current_user.nil?
  end

  def ensure_organization_is_subscribed(script)
    unless current_organization.monitored_scripts.include? script
      flash[:error] = "No access."
    end
  end
end
