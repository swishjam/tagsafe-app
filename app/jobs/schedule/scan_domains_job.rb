module Schedule
  class ScanDomainsJob < ApplicationJob
    def perform
      Domain.all.each{ |domain| domain.scan_and_capture_domains_tags }
    end
  end
end