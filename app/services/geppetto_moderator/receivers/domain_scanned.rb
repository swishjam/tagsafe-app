class GeppettoModerator::Receivers::DomainScanned
  def initialize(tag_urls:, domain_id:, domain_scan_id:, error_message:, initial_scan:)
    @tag_urls = tag_urls
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
      UpdateDomainsTagsJob.perform_later(
        domain: domain, 
        tag_urls: @tag_urls, 
        domain_scan: domain_scan, 
        initial_scan: @initial_scan
      )
    end
  end

  def domain
    @domain ||= Domain.find(@domain_id)
  end

  def domain_scan
    @domain_scan ||= DomainScan.find(@domain_scan_id)
  end
end