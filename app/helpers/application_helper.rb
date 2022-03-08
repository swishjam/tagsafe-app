module ApplicationHelper
  include HtmlHelper
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def current_domain
    @current_domain ||= session[:current_domain_id] ? current_user&.domains&.find(session[:current_domain_id]) : current_user&.domains&.first
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def current_domain_user
    @current_domain_user ||= current_user.domain_user_for(current_domain)
  end

  def set_current_domain_for_user(user, domain)
    raise 'Cannot update domain to user that does not belong to it' unless user.domains.include? domain
    session[:current_domain_id] = domain.id
  end

  def log_user_in(user, domain = user.domains.first)
    session[:user_id] = user.id
    session[:current_domain_id] = domain&.id
  end

  def log_user_out
    session.delete(:user_id)
    session.delete(:current_domain_id)
  end

  def stream_modal(partial:, turbo_frame_name: 'server_loadable_modal', locals: {})
    render turbo_stream: turbo_stream.replace(
      turbo_frame_name,
      partial: partial,
      locals: locals
    )
  end

  def permitted_to_view?(*models, raise_error: false)
    models.each do |model|
      case model.class.to_s
      when 'Tag'
        no_access!(raise_error) unless current_domain.tags.include? model
      when 'TagVersion'
        no_access!(raise_error) unless current_domain.tags.include? model.tag
      when 'Audit'
        no_access!(raise_error) unless current_domain.tags.include? model.tag
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
end
