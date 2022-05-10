class UptimeCheckBatch < ApplicationRecord
  belongs_to :uptime_region
  has_many :uptime_checks
end