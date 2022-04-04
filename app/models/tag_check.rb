class TagCheck < ApplicationRecord
  belongs_to :tag
  belongs_to :tag_check_region
  has_one :tag_version, foreign_key: :tag_check_captured_with_id

  scope :measured_uptime, -> { where.not(response_code: nil, response_time_ms: nil) }
  scope :did_not_measure_uptime, -> { where(response_code: nil, response_time_ms:nil )}
  scope :release_monitoring_only, -> { did_not_measure_uptime }

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: [200, 204]) }
  
  scope :captured_new_tag_version, -> { joins(:tag_version).where.not(tag_version: nil) }
  scope :billable_for_domain, -> (domain) { joins(:tag).where(tag: { domain_id: domain.id }) }
  scope :by_tag_check_region, -> (tag_check_region_or_regions) { where(tag_check_region: tag_check_region_or_regions) }

  def captured_new_tag_version?
    tag_version.present?
  end

  def measured_uptime?
    response_code.present? && response_time_ms.present?
  end

  def did_not_measure_uptime?
    !measured_uptime?
  end
  alias for_release_monitoring_only? did_not_measure_uptime?
end