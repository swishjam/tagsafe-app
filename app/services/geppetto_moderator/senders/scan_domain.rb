class GeppettoModerator::Senders::ScanDomain < GeppettoModerator::Senders::Base

  def initialize(domain)
    @endpoint = "/api/scan_domain"
    @domain = domain
  end

  def request_body
    {
      domain_id: @domain.id,
      domain_url: @domain.url
    }
  end
end