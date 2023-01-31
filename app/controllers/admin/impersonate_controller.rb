module Admin
  class ImpersonateController < BaseController
    def impersonate
      @user = User.find_by!(uid: params[:user_uid])
      session[:impersonating_user_uid] = @user.uid
      redirect_to containers_path
    end

    def un_impersonate
      session.delete(:impersonating_user_uid)
      redirect_to containers_path
    end
  end
end