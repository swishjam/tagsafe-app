class Domain < ApplicationRecord
  include Flaggable
  uid_prefix 'dom'
  acts_as_paranoid

  belongs_to :organization
  has_many :performance_audit_calculators
  has_many :url_crawls, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :urls_to_crawl, dependent: :destroy, class_name: 'UrlToCrawl'
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  after_create_commit :add_defaults

  def parsed_domain_url
    u = URI.parse(url)
    "#{u.scheme}://#{u.hostname}"
  end

  def url_hostname
    URI.parse(url).hostname
  end

  def add_defaults(create_mock_site = true)
    urls_to_crawl.create(url: url)
    PerformanceAuditCalculator.create_default_calculator(self)
  end

  def current_performance_audit_calculator
    performance_audit_calculators.currently_active.limit(1).first
  end

  def disable_all_third_party_tags_during_audits
    # ENV['DISABLE_ALL_THIRD_PARTY_TAGS_IN_AUDITS'] === 'true'
    true
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def crawl_and_capture_domains_tags(initial_crawl = false)
    urls_to_crawl.each{ |url_to_crawl| url_to_crawl.crawl_later(initial_crawl) }
  end

  def should_capture_tag?(url)
    non_third_party_url_patterns.none?{ |url_pattern| url.include?(url_pattern.pattern) } 
  end

  def crawl_in_progress?
    url_crawls.pending.any?
  end

  def user_can_initiate_crawl?(user)
    return false if user.nil?
    organization.users.include?(user)
  end
end