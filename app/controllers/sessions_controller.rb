class SessionsController < ApplicationController
  layout 'logged_out_layout'

  def create
    user = User.find_by(email: params[:login][:email].downcase)
    if user && user.authenticate(params[:login][:password])
      log_user_in(user)
      display_toast_message("Welcome, #{user.email}.")
      url_to_go_to = session[:redirect_url] || tags_path
      session.delete(:redirect_url)
      redirect_to url_to_go_to
    else
      display_inline_error("Incorrect email or password, try again.")
      render :new
    end
  end

  def destroy
    session.delete(:user_id)
    session.delete(:current_domain_id)
    redirect_to login_path
  end
end