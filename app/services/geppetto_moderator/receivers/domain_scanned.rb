class GeppettoModerator::Receivers::DomainScanned
  def initialize(scripts:, domain_id:, error:)
    @scripts = scripts
    @domain_id = domain_id
    @error = error
  end

  def receive!
    domain = Domain.find(@domain_id)
    if @error
      Rails.logger.error "Error encountered in domain scan.\nDomain #{domain.url}.\nError: #{@error}"
    else
      UpdateDomainsScriptsJob.perform_later(domain, @scripts)
    end
  end
end