module Admin
  class BaseController < LoggedInController
    before_action :verify_admin
  
    def verify_admin
    end
  end
end