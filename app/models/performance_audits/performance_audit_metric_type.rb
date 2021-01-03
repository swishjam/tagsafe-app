class PerformanceAuditMetricType < ApplicationRecord
  scope :by_key, -> (key) { where(key: key) }

  # add this to DB
  def unit_abbrev
    unit == 'milliseconds' ? 'ms' : unit
  end
end