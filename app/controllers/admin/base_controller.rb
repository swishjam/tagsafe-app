module Admin
  class BaseController < LoggedInController
    layout 'admin_layout'
    before_action :verify_admin
    before_action :hide_side_navigation
  
    def verify_admin
      redirect_to root_path if user_is_anonymous? || !current_user.is_tagsafe_admin?(@container)
    end

    def hide_side_navigation
      @hide_navigation = true
    end
  end
end