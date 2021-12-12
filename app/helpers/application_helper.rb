module ApplicationHelper
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def current_domain
    @current_domain ||= session[:current_domain_id] ? current_organization&.domains&.find(session[:current_domain_id]) : current_organization&.domains&.first
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def set_current_domain_for_user(user, domain)
    raise 'Cannot update domain to user that does not belong to it' unless user.organizations.collect{ |org| org.domains }.flatten!.include? domain
    session[:current_domain_id] = domain.id
  end

  def current_organization
    @current_organization ||= session[:current_organization_id] ? Organization.find(session[:current_organization_id]) : current_user && current_user.organizations.first
  rescue ActiveRecord::RecordNotFound => e
    log_user_out
  end

  def set_current_organization_for_user(user, organization)
    raise 'Cannot update organization to user that does not belong to it' unless user.organizations.include? organization
    session[:current_organization_id] = organization.id
  end

  def log_user_in(user, organization = user.organizations&.first, domain = organization&.domains&.first)
    session[:user_id] = user.id
    session[:current_organization_id] = organization&.id
    session[:current_domain_id] = domain&.id
  end

  def log_user_out
    session.delete(:user_id)
    session.delete(:current_domain_id)
    session.delete(:current_organization_id)
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

  def loading_submit_button(btn_text, button_class: nil)
    "<button type='submit' class='tagsafe-btn loading-button #{button_class}'><span class='submit-text'>#{btn_text}</span>#{display_loading_icon color: 'white', size: 'small'}</button>".html_safe
  end
  alias submit_loading_button loading_submit_button

  def display_loading_spinner(opts = {})
    render 'partials/utils/spinner', opts
  end
  alias display_loading_icon display_loading_spinner

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
