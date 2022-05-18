class SessionsController < ApplicationController
  layout 'logged_out_layout'

  def new
    redirect_to tags_path if current_user
    @hide_logged_out_nav = true
    if params[:domain]
      @domain = Domain.find_by(uid: params[:domain])
    end
  end

  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user && @user.authenticate(params[:password])
      # if params[:domain_uid]
      #   domain = Domain.find_by(uid: params[:domain_uid])
      #   domain.mark_as_registered!
      #   domain.add_user(@user)
      #   set_current_domain(@domain)
      #   set_current_user(@user)
      # else
      #   set_current_user(@user)
      # end
      current_domain.add_user(@user) if current_domain && !@user.belongs_to_domain?(current_domain)
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