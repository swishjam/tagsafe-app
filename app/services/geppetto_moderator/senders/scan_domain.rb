class GeppettoModerator::Senders::ScanDomain < GeppettoModerator::Senders::Base

  def initialize(domain, initial_scan: false)
    @endpoint = "/api/scan_domain"
    @domain = domain
    @initial_scan = initial_scan
  end

  def request_body
    {
      domain_scan_id: domain_scan.id,
      domain_id: @domain.id,
      domain_url: @domain.url,
      initial_scan: @initial_scan
    }
  end

  private

  def domain_scan
    @domain_scan ||= DomainScan.create(domain: @domain, scan_enqueued_at: Time.now)
  end
end