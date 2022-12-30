class PageLoadPerformanceMetric < ApplicationRecord
  belongs_to :container
  belongs_to :page_load
  belongs_to :page_url

  scope :by_type, -> (type_or_types) { where(type: type_or_types) }
end