module Admin
  class BaseController < LoggedInController
    before_action :verify_admin
    before_action :hide_side_navigation

    layout 'admin_layout'
  
    def verify_admin
      redirect_to root_path unless current_user.is_tagsafe_admin?
    end

    def hide_side_navigation
      @hide_navigation = true
    end
  end
end