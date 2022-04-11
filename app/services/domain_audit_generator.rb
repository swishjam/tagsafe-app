# class DomainAuditGenerator
#   attr_accessor :page_url, :domain, :domain_audit
#   def initialize(url)
#     @provided_url = url
#     unless @provided_url.starts_with?('http')
#       @provided_url = "https://#{@provided_url}"
#     end
#   end

#   def create_domain_audit
#     @domain = Domain.create(url: @provided_url, is_generating_third_party_impact_trial: true)
#     if domain.persisted? && page_url&.persisted?
#       @domain_audit = DomainAudit.create(domain: domain, page_url: page_url)
#     end
#   end

#   private

#   def create_new_domain_and_page_url
#     @domain = 
#     @page_url = create_new_page_url! if existing_page_url.nil? && domain.valid?
#   end

#   def create_new_page_url!
#     @page_url ||= @existing_domain.add_url(@provided_url, should_scan_for_tags: false)
#   end

#   def existing_page_url
#     return @page_url = nil if existing_domain.nil?
#     @page_url ||= existing_domain.page_urls.find_by(full_url: @provided_url)
#   end

#   def existing_domain
#     @domain ||= Domain.find_by(url: provided_url_normalized_to_domain_url)
#   end

#   def parsed_url
#     @parsed_url ||= URI.parse(@provided_url)
#   end

#   def provided_url_normalized_to_domain_url
#     @provided_url_normalized_to_domain_url ||= "#{parsed_url.scheme}://#{parsed_url.hostname}"
#   end
# end