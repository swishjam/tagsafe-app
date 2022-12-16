class PageUrlTagFoundOn < ApplicationRecord
  self.table_name = :page_urls_tag_found_on
  
  belongs_to :tag
  belongs_to :page_url

  validates_uniqueness_of :tag_id, scope: :page_url_id

  before_create { self.last_seen_at = Time.current }
end