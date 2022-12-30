class PageLoadPerformanceMetric < ApplicationRecord
  belongs_to :container
  belongs_to :page_load
  belongs_to :page_url

  scope :by_type, -> (type_or_types) { where(type: type_or_types) }

  TYPES = %w[
    DomCompletePerformanceMetric
    DomInteractivePerformanceMetric
    FirstContentfulPaintPerformanceMetric
    TimeToFirstBytePerformanceMetric
    TotalBlockingTimePerformanceMetric
  ]

  def self.friendly_name
    self.to_s.gsub('PerformanceMetric', '').split(/(?=[A-Z])/).join(' ').gsub('Dom', 'DOM')
  end
end