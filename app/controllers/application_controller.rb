class ApplicationController < ActionController::Base
  class NoAccessError < StandardError; end
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :current_domain
  helper_method :current_organization

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def current_domain
    @current_domain ||= session[:current_domain_id] ? current_organization&.domains&.find(session[:current_domain_id]) : current_organization&.domains&.first
  end

  def current_organization
    @current_organization ||= current_user && current_user.organization
  end

  def permitted_to_view?(*models, raise_error: false)
    models.each do |model|
      case model.class.to_s
      when 'Script'
        no_access!(raise_error) unless current_domain.subscribed_to_script? model
      when 'ScriptSubscriber'
        no_access!(raise_error) unless current_domain.script_subscriptions.include? model
      when 'ScriptChange'
        no_access!(raise_error) unless current_domain.subscribed_to_script? model.script
      when 'Audit'
        no_access!(raise_error) unless current_domain.script_subscriptions.include? model.script_subscriber
      else
        raise "Invalid model provided to permitted_to_view?: #{model.class}"
      end
    end
  end

  def render_breadcrumbs(*crumbs)
    @breadcrumbs = crumbs
  end

  def no_access!(raise_error)
    raise NoAccessError if raise_error
    flash[:banner_error] = "No access."
    redirect_to scripts_path
  end

  def authorize!
    if current_user.nil?
      flash[:banner_error] = "Please login."
      redirect_to login_path 
    end
  end

  def ensure_logged_out
    redirect_to scripts_path unless current_user.nil?
  end

  def display_toast_message(*messages)
    flash[:toast_messages] = messages
  end
  alias display_toast_messages display_toast_message

  def display_toast_error(*messages)
    flash[:toast_errors] = messages
  end
  alias display_toast_errors display_toast_error

  def display_inline_errors(*messages)
    flash[:inline_errors] = messages
  end
  alias display_inline_error display_inline_errors
end
