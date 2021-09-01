class GeppettoModerator::Senders::ScanDomain < GeppettoModerator::Senders::Base
  def initialize(domain, scan_urls:, initial_scan: false)
    @endpoint = "/api/scan_domain"
    @domain = domain
    @urls_to_scan = scan_urls
    @initial_scan = initial_scan
  end

  def send!
    @urls_to_scan.each do |url_to_scan|
      scan = DomainScan.create(domain: @domain, url: url_to_scan.url, scan_enqueued_at: Time.now)
      overridden_send!(scan, url_to_scan.url)
    end
  end

  private

  # allows us to loop over each url to scan
  def overridden_send!(domain_scan, url)
    GeppettoModerator::Sender.new(endpoint, domain, {
      domain_scan_id: domain_scan.id,
      domain_id: @domain.id,
      scan_url: url,
      initial_scan: @initial_scan
    }).send!
  end
end