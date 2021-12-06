class PageUrl < ApplicationRecord
  uid_prefix 'url'
  belongs_to :domain
  has_many :audits
  has_many :url_crawls

  scope :should_run_audits_on, -> { where(should_run_audits_on: true) }
  scope :should_not_run_audits_on, -> { where(should_run_audits_on: false) }
  scope :should_scan_for_tags, -> { where(should_scan_for_tags: true) }
  scope :should_not_scan_for_tags, -> { where(should_scan_for_tags: false) }

  before_create :enforce_root_pathname

  def should_run_audits?
    should_run_audits_on
  end

  def should_scan_for_tags?
    should_scan_for_tags
  end

  def crawl_later(initial_crawl = false)
    crawl = url_crawls.create!(domain_id: domain_id)
    CrawlUrlJob.perform_later(crawl, initial_crawl: initial_crawl)
  end
  
  def crawl_now(initial_crawl = false)
    crawl = url_crawls.create!(domain_id: domain_id)
    CrawlUrlJob.perform_now(crawl, initial_crawl: initial_crawl)
  end

  private

  def enforce_root_pathname
   pathname = pathname == '' ? '/' : pathname
  end
end