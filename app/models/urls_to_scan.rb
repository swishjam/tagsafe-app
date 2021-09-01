class UrlsToScan < ApplicationRecord
  belongs_to :domain

  after_create :scan_new_url

  validate :contains_domain
  validate :cannot_remove_last_record, on: :destroy

  private

  def scan_new_url
    if domain.urls_to_scans.count == 1
      domain.scan_and_capture_domains_tags(scan_urls: [self], initial_scan: true)
    else
      domain.scan_and_capture_domains_tags(scan_urls: [self], initial_scan: false)
    end
  end

  def cannot_remove_last_record
    if domain.urls_to_scans.count == 1
      errors.add(:base, "Must have at least one URL to scan.")
    end
  end

  def contains_domain
    unless url.include?(domain.url)
      errors.add(:url, "must contain #{domain.url}")
    end
  end
end