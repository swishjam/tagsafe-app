class GeppettoModerator::Senders::ScanDomain < GeppettoModerator::Senders::Base

  def initialize(domain)
    @endpoint = "/api/scan_domain"
    @domain = domain
  end

  def request_body
    {
      domain_scan_id: domain_scan.id,
      domain_id: @domain.id,
      domain_url: @domain.url
    }
  end

  private

  def domain_scan
    @domain_scan ||= DomainScan.create(domain: @domain, scan_enqueued_at: Time.now)
  end
end