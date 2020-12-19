class GeppettoModerator::Receivers::DomainScanned
  def initialize(scripts:, domain_id:, domain_scan_id:, error_message:)
    @scripts = scripts
    @domain_id = domain_id
    @domain_scan_id = domain_scan_id
    @error_message = error_message
  end

  def receive!
    domain_scan.completed!
    domain = Domain.find(@domain_id)
    if @error_message
      domain_scan.errored!(@error_message)
    else
      UpdateDomainsScriptsJob.perform_later(domain, @scripts)
    end
  end

  def domain
    @domain ||= Domain.find(@domain_id)
  end

  def domain_scan
    @domain_scan ||= DomainScan.find(@domain_scan_id)
  end
end