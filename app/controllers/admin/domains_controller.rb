module Admin
  class ContainersController < BaseController
    def index
      @containers = Container.all.order(:url).page(params[:page] || 1).per(10)
    end

    def show
      @container = Container.find_by(uid: params[:uid])
    end
  end
end