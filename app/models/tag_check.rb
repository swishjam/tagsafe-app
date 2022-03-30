class TagCheck < ApplicationRecord
  belongs_to :tag
  belongs_to :tag_check_region, optional: true
  has_one :tag_version, foreign_key: :tag_check_captured_with_id

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: [200, 204]) }
  scope :captured_new_tag_version, -> { joins(:tag_version).where.not(tag_version: nil) }
  scope :billable_for_domain, -> (domain) { joins(:tag).where(tag: { domain_id: domain.id }) }

  def captured_new_tag_version?
    tag_version.present?
  end
end