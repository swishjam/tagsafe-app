module Admin
  class FlagsController < BaseController
    def index
      @flags = Flag.all.order('name ASC')
    end

    def show
      @flag = Flag.find(params[:id])
    end
  end
end