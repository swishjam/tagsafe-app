module ApplicationHelper
  include HtmlHelper
  def current_user
    @current_user ||= User.find_by(uid: session[:current_user_uid]) unless session[:current_user_uid].nil?
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def user_is_anonymous?
    current_user.nil?
  end

  def current_domain
    return @current_domain if defined?(@current_domain)
    if user_is_anonymous?
      return unless session[:current_domain_uid].present?
      @current_domain = Domain.find_by(uid: session[:current_domain_uid])
    else
      @current_domain = session[:current_domain_uid] ? current_user.domains.find_by(uid: session[:current_domain_uid]) : current_user.domains.first
    end
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def current_domain_user
    return if current_user.nil?
    @current_domain_user ||= current_user.domain_user_for(current_domain)
  end

  def current_anonymous_user_identifier
    session[:anonymous_user_identifier]
  end

  def set_current_domain(domain)
    session[:current_domain_uid] = domain.uid
  end

  def set_current_user(user)
    session[:current_user_uid] = user.uid
  end

  def set_anonymous_user_identifier
    session[:anonymous_user_identifier] = SecureRandom.hex(16)
  end

  def log_user_out
    session.delete(:current_user_uid)
    session.delete(:current_domain_uid)
  end

  def stream_modal(partial: "modals/#{action_name}.html.erb", turbo_frame_name: 'server_loadable_modal', locals: {})
    render turbo_stream: turbo_stream.replace(
      turbo_frame_name,
      partial: partial,
      locals: locals
    )
  end

  def respond_with_notification(message: nil, partial: nil, partial_locals: {}, image: nil, timestamp: Time.now.strftime("%m/%d/%y @ %l:%M %P %Z"))
    render turbo_stream: turbo_stream.prepend(
      "request_response_notifications_container",
      partial: 'partials/notification',
      locals: { 
        message: message, 
        partial: partial,
        image: image,
        timestamp: timestamp,
        partial_locals: partial_locals
      }
    )
  end

  def render_breadcrumbs(*crumbs)
    @breadcrumbs = crumbs
  end

  def no_access!(raise_error)
    raise NoAccessError if raise_error
    flash[:banner_error] = "No access."
    redirect_to tags_path
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

  def display_success_banner(message)
    flash[:banner_success_messages] = [message]
  end

  def display_error_banner(message)
    flash[:banner_error_messages] = [message]
  end

  def pluralize_if_necessary(singular_term, list)
    "#{singular_term}#{list.count > 1 ? 's' : nil}"
  end

  def add_query_params_to_url(url_string, params = {})
    uri = URI(url_string)
    params = Hash[URI.decode_www_form(uri.query || '')].merge(params)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end
end
