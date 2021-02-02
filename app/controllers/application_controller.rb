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
    @current_organization ||= session[:current_organization_id] ? Organization.find(session[:current_organization_id]) : current_user && current_user.organizations.first
  end

  def log_user_in(user)
    session[:user_id] = user.id
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

  def display_toast_message(message)
    display_toast_messages([message])
  end

  def display_toast_messages(messages)
    flash[:toast_messages] = messages
  end

  def display_toast_error(message)
    display_toast_errors([message])
  end

  def display_toast_errors(messages)
    flash[:toast_errors] = messages
  end

  def display_inline_error(message)
    display_inline_errors([message])
  end

  def display_inline_errors(messages)
    flash[:inline_errors] = messages
  end
end
