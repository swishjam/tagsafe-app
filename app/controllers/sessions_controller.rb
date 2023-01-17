class SessionsController < ApplicationController
  layout 'logged_out_layout'

  def new
    redirect_to container_tag_snippets_path(@container) if current_user
  end

  def create
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      # @container.add_user(user) if @container && !@user.belongs_to_container?(@container)
      set_current_user(user)
      url_to_go_to = session[:redirect_url] || container_tag_snippets_path(@container)
      session.delete(:redirect_url)
      redirect_to url_to_go_to
    else
      render turbo_stream: turbo_stream.replace(
        "login_form",
        partial: 'sessions/form',
        locals: { error_message: "Invalid email or password." }
      )
    end
  end

  def destroy
    log_user_out
    redirect_to params[:redirect_path] || login_path
  end
end