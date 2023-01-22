module ApplicationHelper
  include HtmlHelper
  def current_user
    @current_user ||= User.find_by(uid: session[:current_user_uid]) unless session[:current_user_uid].nil?
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
    redirect_to new_session_path
  end

  def user_is_anonymous?
    current_user.nil?
  end

  def current_container_user
    return if current_user.nil?
    @container_user ||= current_user.container_user_for(@container)
  end

  def current_anonymous_user_identifier
    session[:anonymous_user_identifier]
  end

  def set_current_user(user)
    session[:current_user_uid] = user.uid
  end

  def log_user_out
    session.delete(:current_user_uid)
  end

  def stream_modal(partial: "modals/#{action_name}", turbo_frame_name: 'server_loadable_modal', locals: {})
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

  def render_default_navigation_items(active_item = nil)
    render_navigation_items(
      { 
        url: container_tag_snippets_path(@container), 
        text: 'Tags', 
        active: active_item == :tags 
      },
      { 
        url: container_change_requests_path(@container), 
        text: 'Change Requests',
        active: active_item == :change_requests,
        turbo_frame: {
          name: "#{@container.uid}_change_requests_count_indicator",
          stream: "#{@container.uid}_change_requests_count_indicator_stream",
          src: count_container_change_requests_path(@container)
        }
      },
      { 
        url: container_page_performance_path(@container), 
        text: 'Page Performance',
        active: active_item == :page_performance,
      },
      { 
        url: container_settings_path(@container), 
        text: 'Settings',
        active: active_item == :settings,
      },
    )
  end

  def render_navigation_items(*items)
    @navigation_items = items
  end

  def render_breadcrumbs(*crumbs)
    @breadcrumbs = crumbs
  end

  def no_access!(raise_error)
    raise NoAccessError if raise_error
    flash[:banner_error] = "No access."
    redirect_to container_tag_snippets_path(@container)
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
