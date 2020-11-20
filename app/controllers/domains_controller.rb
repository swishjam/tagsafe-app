class DomainsController < ApplicationController

  # def new
  #   @domain = Domain.new
  # end

  # def index
  #   @domains = current_organization.domains
  # end

  # def create
  #   params[:domain][:organization_id] = current_organization.id
  #   domain = Domain.create(domain_params)
  #   flash[:notice] = "Scan in process for #{domain.url}."
  #   redirect_to domain_path(domain.id)
  # end

  # def show
  #   @domain = Domain.find(params[:id])
  # end

  def update_current_domain
    domain = Domain.find(params[:id])
    session[:current_domain_id] = domain.id
    flash[:notice] = "Domain updated to #{domain.url}"
    redirect_to scripts_path
  end

  def scan
    domain = Domain.find(params[:id])
    domain.scan_and_capture_domains_scripts
    flash[:notice] = "Scan in process for #{domain.url}."
    redirect_to domain_path(domain.id)
  end

  # def run_test_suite
  #   domain = Domain.find(params[:id])
  #   domain.run_test_suite!
  #   flash[:message] = "Running test suite on #{domain.url}"
  #   redirect_to domain_path(domain)
  # end

  private

  def domain_params
    params.require(:domain).permit(:url, :organization_id)
  end
end