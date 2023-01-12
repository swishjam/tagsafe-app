class PageUrl < ApplicationRecord
  class InvalidUrlError < StandardError; end;
  uid_prefix 'url'

  belongs_to :container
  has_many :audits
  has_many :tagsafe_js_event_batches, class_name: TagsafeJsEventBatch.to_s
  has_many :page_loads, dependent: :destroy
  has_many :page_load_performance_metrics
  has_many :page_urls_tag_found_on, class_name: PageUrlTagFoundOn.to_s, dependent: :destroy
  has_many :tags, through: :page_urls_tag_found_on

  validates_uniqueness_of :full_url, scope: :container_id, message: Proc.new{ |page_url| "#{page_url.full_url} already exists for Container #{page_url.container.name}."}

  before_create :set_parsed_url

  def is_root?
    ['/', ''].include?(pathname)
  end

  def friendly_url
    hostname + (is_root? ? '' : pathname)
  end

  def url_without_query_params
    parsed = parsed_url
    parsed.query = nil
    parsed.to_s
  end

  def parsed_url
    URI.parse(full_url)
  end

  private
  
  def set_parsed_url
    self.hostname = parsed_url.host
    self.pathname = parsed_url.path
  end
end