class GeppettoModerator::Receivers::DomainScanned
  def initialize(scripts:, domain_id:, domain_scan_id:, error_message:, initial_scan:)
    @scripts = scripts
    @domain_id = domain_id
    @domain_scan_id = domain_scan_id
    @error_message = error_message
    @initial_scan = initial_scan
  end

  def receive!
    domain = Domain.find(@domain_id)
    if @error_message
      domain_scan.errored!(@error_message)
    else
      UpdateDomainsScriptsJob.perform_later(domain, @scripts, domain_scan, @initial_scan)
    end
  end

  def domain
    @domain ||= Domain.find(@domain_id)
  end

  def domain_scan
    @domain_scan ||= DomainScan.find(@domain_scan_id)
  end
end