class PageUrl < ApplicationRecord
  class InvalidUrlError < StandardError; end;
  uid_prefix 'url'
  belongs_to :domain
  has_many :audits
  has_many :tags_found_on_url, class_name: Tag.to_s, foreign_key: :found_on_page_url_id

  validates_uniqueness_of :full_url, scope: :domain_id, message: Proc.new{ |page_url| "#{page_url.full_url} already exists on #{domain.url}."}

  def self.create_or_find_by_url(domain, url, should_scan_for_tags: false)
    existing_page_url = domain.page_urls.find_by_unsanitized_url(url)
    existing_page_url || domain.add_url(url, should_scan_for_tags: should_scan_for_tags)
  end

  def self.find_by_unsanitized_url(url)
    parsed_url = get_valid_parsed_url(url)
    where(full_url: parsed_url.to_s).limit(1).first
  end

  def friendly_url
    hostname + (pathname == '/' ? '' : pathname)
  end

  private

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

  def enforce_url_is_valid_and_can_be_reached
    parsed_url = domain.is_test_domain? ? URI.parse(full_url) : self.class.get_valid_parsed_url(full_url)
    self.full_url = parsed_url.to_s
    self.hostname = parsed_url.host
    self.pathname = parsed_url.path == '' ? '/' : parsed_url.path
  rescue InvalidUrlError => e
    errors.add(:base, e.message)
  end

  def self.get_valid_parsed_url(url_to_check)
    resp = HTTParty.get(url_to_check, :headers => { 'User-Agent' => "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0" })
    resp.request.last_uri
  rescue => e
    raise InvalidUrlError, "Cannot access #{url_to_check}: #{e.message}"
  end
end