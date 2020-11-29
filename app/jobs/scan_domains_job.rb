class ScanDomainsJob < ApplicationJob
  def perform
    Domain.active.each{ |domain| domain.scan_and_capture_domains_scripts }
  end
end