class PageUrl < ApplicationRecord
  class InvalidUrlError < StandardError; end;
  uid_prefix 'url'
  belongs_to :domain
  has_many :audits
  has_many :url_crawls
  has_many :tags_found_on_url, class_name: Tag.to_s, foreign_key: :found_on_page_url_id

  scope :should_scan_for_tags, -> { where(should_scan_for_tags: true) }
  scope :should_not_scan_for_tags, -> { where(should_scan_for_tags: false) }

  before_validation :enforce_url_is_valid_and_can_be_reached
  after_create :scan_for_tags_if_necessary
  after_update :scan_for_tags_if_became_scannable

  validate :is_part_of_domain_url
  validate :at_least_one_scannable_url, on: :update
  validates_uniqueness_of :full_url, scope: :domain_id, message: Proc.new{ |page_url| "#{page_url.full_url} already exists on #{domain.url}."}

  def self.create_or_find_by_url(domain, url, should_scan_for_tags: false)
    existing_page_url = domain.page_urls.find_by_unsanitized_url(url)
    existing_page_url || domain.add_url(url, should_scan_for_tags: should_scan_for_tags)
  end

  def self.find_by_unsanitized_url(url)
    parsed_url = get_valid_parsed_url(url)
    where(full_url: parsed_url.to_s).limit(1).first
  end

  def should_scan_for_tags?
    !domain.is_generating_third_party_impact_trial && should_scan_for_tags
  end

  def crawl_for_tags!
    url_crawls.create!(domain_id: domain_id)
  end

  private

  def scan_for_tags_if_became_scannable
    updated_to_scan = saved_changes['should_scan_for_tags'] && saved_changes['should_scan_for_tags'][1] == true
    crawl_for_tags! if updated_to_scan
  end

  def scan_for_tags_if_necessary
    crawl_for_tags! if should_scan_for_tags?
  end

  def is_part_of_domain_url
    # simplify things by not providing multiples errors, weird results if `enforce_url_is_valid_and_can_be_reached` returns an error first
    return if errors.any? 
    if ENV['ALLOW_DIFFERENT_SUBDOMAIN_PER_DOMAIN'] == 'false'
      if domain.url_hostname != hostname
        errors.add(:base, "Invalid URL #{full_url}. Must be a part of the #{domain.url_hostname} domain.")
      end
    else
      split_hostname = hostname.split('.')
      split_hostname.shift
      hostname_without_subdomain = split_hostname.join('')

      split_domain_hostname = domain.url_hostname.split('.')
      split_domain_hostname.shift
      domain_hostname_without_subdomain = split_domain_hostname.join('')
      
      if hostname_without_subdomain != domain_hostname_without_subdomain
        errors.add(:base, "Invalid URL #{full_url}. Must be a part of the *.#{domain_hostname_without_subdomain} domain.")
      end
    end
  end

  def at_least_one_scannable_url
    updated_to_do_not_scan = changes['should_scan_for_tags'] && changes['should_scan_for_tags'][1] == false
    if updated_to_do_not_scan
      was_the_only_page_url_to_scan = domain.page_urls.should_scan_for_tags.count == 1
      if was_the_only_page_url_to_scan
        errors.add(:base, "Must have at least one URL to scan for third party tags.")
      end
    end
  end

  def enforce_url_is_valid_and_can_be_reached
    parsed_url = domain.is_test_domain? ? URI.parse(full_url) : self.class.get_valid_parsed_url(full_url)
    self.full_url = parsed_url.to_s
    self.hostname = parsed_url.host
    self.pathname = parsed_url.path == '' ? '/' : parsed_url.path
  rescue InvalidUrlError => e
    errors.add(:base, e.message)
  end

  def self.get_valid_parsed_url(url_to_check, attempt_number: 1)
    raise InvalidUrlError, "request redirected the maximum 10 times." if attempt_number > 10
    uri = URI.parse(url_to_check)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    resp = http.get(uri.request_uri, { 'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" })
    case resp.class.to_s
    when Net::HTTPOK.to_s, Net::HTTPFound.to_s
      uri
    when Net::HTTPMovedPermanently.to_s
      get_valid_parsed_url(resp['location'], attempt_number: attempt_number+1)
    else
      raise InvalidUrlError, "Returned a status of: #{resp.code}"
    end
  rescue => e
    raise InvalidUrlError, "Cannot access #{url_to_check}: #{e.message}"
  end
end