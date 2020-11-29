class DomainsController < ApplicationController
  def update_current_domain
    domain = Domain.find(params[:id])
    session[:current_domain_id] = domain.id
    flash[:notice] = "Domain updated to #{domain.url}"
    redirect_to scripts_path
  end

  def scan
    domain = Domain.find(params[:id])
    domain.scan_and_capture_domains_scripts
    flash[:banner_message] = "Scan in process for #{domain.url}."
    redirect_to domain_path(domain.id)
  end
end