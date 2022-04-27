class LongTask < ApplicationRecord
  belongs_to :performance_audit
  belongs_to :tag, optional: true
  belongs_to :tag_version, optional: true
end