class TagCheck < ApplicationRecord
  
  belongs_to :tag
  belongs_to :tag_check_region, optional: true

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: 200) }
end