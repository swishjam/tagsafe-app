class Domain < ApplicationRecord
  belongs_to :organization
  has_many :url_crawls, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :urls_to_crawl, dependent: :destroy, class_name: 'UrlToCrawl'
  has_many :non_third_party_url_patterns, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  after_create_commit :add_default_url_to_crawl

  def add_default_url_to_crawl
    # response = HTTParty.get(url) # validate url is accessible...?
    urls_to_crawl.create(url: url)
  end

  def disable_all_third_party_tags_during_audits
    # ENV['DISABLE_ALL_THIRD_PARTY_TAGS_IN_AUDITS'] === 'true'
    false
  end

  def has_tag?(tag)
    tags.include? tag
  end

  def allowed_third_party_tag_urls
    tags.third_party_tags_that_shouldnt_be_blocked.collect(&:full_url)
  end

  def crawl_and_capture_domains_tags(initial_crawl = false)
    urls_to_crawl.each{ |url_to_crawl| url_to_crawl.crawl!(initial_crawl) }
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