class GeppettoModerator::Receivers::DomainScanned
  def initialize(scripts:, domain_id:)
    @scripts = scripts
    @domain_id = domain_id
  end

  def receive!
    domain = Domain.find(@domain_id)
    UpdateDomainsScriptsJob.perform_later(domain, @scripts)
  end
end