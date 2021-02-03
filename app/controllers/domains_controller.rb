class DomainsController < ApplicationController
  def create
    params[:domain][:organization_id] = current_organization.id
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    domain = Domain.create(domain_params)
    if domain.valid?
      display_toast_message("Scanning #{domain.url} for third party tags.")
    else
      display_toast_error(domain.errors.full_messages.join(' '))
    end
    redirect_to request.referrer
  end

  def update
    params[:domain][:url] = "#{params[:domain][:protocol]}#{params[:domain][:url]}"
    domain = Domain.find(params[:id])
    if domain.update(domain_params)
      domain.scan_and_capture_domains_scripts
      display_toast_message("Scanning #{domain.url} for third party tags.")
    else
      display_toast_error(domain.errors.full_messages.join(' '))
    end
    redirect_to request.referrer
  end

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

  private

  def domain_params
    params.require(:domain).permit(:url, :organization_id)
  end
end