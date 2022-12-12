class PageUrl < ApplicationRecord
  class InvalidUrlError < StandardError; end;
  uid_prefix 'url'

  belongs_to :container
  has_many :audits
  has_many :tagsafe_js_event_batches, class_name: TagsafeJsEventBatch.to_s
  has_many :tags_found_on_url, class_name: Tag.to_s, foreign_key: :found_on_page_url_id

  validates_uniqueness_of :full_url, scope: :container_id, message: Proc.new{ |page_url| "#{page_url.full_url} already exists for Container #{container.name}."}

  before_create :set_parsed_url

  def friendly_url
    hostname + (pathname == '/' ? '' : pathname)
  end

  private
  
  def set_parsed_url
    parsed_url = URI.parse(self.full_url)
    self.hostname = parsed_url.host
    self.pathname = parsed_url.path
  end
end