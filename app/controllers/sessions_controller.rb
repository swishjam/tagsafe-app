class SessionsController < ApplicationController
  layout 'logged_out_layout'

  def new
    redirect_to tags_path if current_user
    @hide_footer = true
    @hide_logged_out_nav = true
    if params[:container]
      @container = Container.find_by(uid: params[:container])
    end
  end

  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user && @user.authenticate(params[:password])
      current_container.add_user(@user) if current_container && !@user.belongs_to_container?(current_container)
      set_current_user(@user)
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