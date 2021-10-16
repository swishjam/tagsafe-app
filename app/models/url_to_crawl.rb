class UrlToCrawl < ApplicationRecord
  self.table_name = :urls_to_crawl
  acts_as_paranoid

  belongs_to :domain

  after_create :crawl_new_url

  validate :contains_domain
  validate :cannot_remove_last_record, on: :destroy

  scope :should_crawl, -> { all }

  def crawl_later(initial_crawl = false)
    CrawlUrlJob.perform_later(self, initial_crawl: initial_crawl)
  end
  
  def crawl_now(initial_crawl = false)
    CrawlUrlJob.perform_now(self, initial_crawl: initial_crawl)
  end

  private

  def crawl_new_url
    crawl_later(domain.urls_to_crawl.count == 1)
  end

  def cannot_remove_last_record
    if domain.urls_to_scans.count == 1
      errors.add(:base, "Must have at least one URL to crawl.")
    end
  end

  def contains_domain
    unless url.include?(domain.url)
      errors.add(:url, "must contain #{domain.url}")
    end
  end
end