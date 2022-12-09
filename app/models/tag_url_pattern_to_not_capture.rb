class TagUrlPatternToNotCapture < ApplicationRecord
  self.table_name = :tag_url_patterns_to_not_capture
  belongs_to :domain

  validates_uniqueness_of :url_pattern, scope: :domain_id
end