class TagCheck < ApplicationRecord
  belongs_to :tag
  belongs_to :tag_check_region, optional: true
  has_one :tag_version, foreign_key: :tag_check_captured_with_id

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: 200) }
end