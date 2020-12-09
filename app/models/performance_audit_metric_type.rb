class PerformanceAuditMetricType < ApplicationRecord
  scope :by_key, -> (key) { where(key: key) }
end