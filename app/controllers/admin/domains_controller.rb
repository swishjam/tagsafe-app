module Admin
  class DomainsController < BaseController
    def index
      @domains = Domain.all.order(:url).page(params[:page] || 1).per(10)
    end

    def show
      @domain = Domain.find_by(uid: params[:uid])
    end
  end
end