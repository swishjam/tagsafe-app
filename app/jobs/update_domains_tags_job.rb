class UpdateDomainsTagsJob < ApplicationJob
  @queue = :default
  
  def perform(domain:, tag_urls:, domain_scan:, initial_scan:)
    TagManager::EvaluateDomainTags.new(domain: domain, tag_urls: tag_urls, initial_scan: initial_scan).evaluate!
    domain_scan.completed!
  end
end