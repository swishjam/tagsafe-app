class LighthouseAuditMetricType < ApplicationRecord
  has_many :lighthouse_audit_metrics, dependent: :destroy

  scope :by_key, -> (key) { where(key: key) }
end