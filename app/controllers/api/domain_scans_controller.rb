module Api
  class DomainScansController < BaseController
    def show
      domain_scan = DomainScan.find(params[:id])
      render json: {
        error_message: domain_scan.error_message,
        completed: domain_scan.completed?,
        successful: domain_scan.successful?
      }
    end
  end
end