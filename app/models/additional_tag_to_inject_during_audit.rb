class AdditionalTagToInjectDuringAudit < ApplicationRecord
  self.table_name = :additional_tags_to_inject_during_audit

  belongs_to :tag
  belongs_to :tag_to_inject, class_name: Tag.to_s

  validates_uniqueness_of :tag_id, scope: :tag_to_inject_id
end