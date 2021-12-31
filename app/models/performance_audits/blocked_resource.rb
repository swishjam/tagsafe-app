class BlockedResource < ApplicationRecord
  belongs_to :performance_audit
  validates_presence_of :url, :resource_type
end