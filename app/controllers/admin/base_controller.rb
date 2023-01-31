module Admin
  class BaseController < LoggedInController
    layout 'admin_layout'
    skip_before_action :find_and_validate_container
    before_action :verify_admin
  
    def verify_admin
      redirect_to containers_path if user_is_anonymous? || (!current_user.is_tagsafe_admin? && !tagsafe_admin_is_impersonating_user?)
    end
  end
end