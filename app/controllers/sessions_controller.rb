class SessionsController < ApplicationController
  layout 'logged_out_layout'

  def new
    @hide_logged_out_nav = true
  end

  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user && @user.authenticate(params[:password])
      log_user_in(@user)
      display_toast_message("Welcome, #{@user.email}.")
      url_to_go_to = session[:redirect_url] || tags_path
      session.delete(:redirect_url)
      redirect_to url_to_go_to
    else
      display_inline_error("Incorrect email or password, try again.")
      @hide_logged_out_nav = true
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_user_out
    redirect_to params[:redirect_path] || login_path
  end
end