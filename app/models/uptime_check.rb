class UptimeCheck < ApplicationRecord
  belongs_to :uptime_check_batch
  belongs_to :tag
  belongs_to :uptime_region

  scope :successful, -> { where(response_code: 200) }
  scope :failed, -> { where.not(response_code: [200, 204]) }
  
  scope :billable_for_domain, -> (domain) { joins(:tag).where(tag: { domain_id: domain.id }) }
  scope :by_uptime_region, -> (uptime_region) { where(uptime_region: uptime_region) }
end