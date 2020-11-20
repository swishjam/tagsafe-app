class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:login][:email].downcase)

    if user && user.authenticate(params[:login][:password])
      session[:user_id] = user.id.to_s
      flash[:message] = "Welcome, #{user.email}."
      redirect_to scripts_path
    else
      flash[:local_error] = "Incorrect email or password, try again."
      render :new
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path
  end
end