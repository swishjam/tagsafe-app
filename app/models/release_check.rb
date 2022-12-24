class ReleaseCheck < ApplicationRecord
  belongs_to :release_check_batch
  belongs_to :tag
  has_one :tag_version, foreign_key: :release_check_captured_with_id

  scope :bypassed_change_detection_because_tag_was_pending_tag_version_capture, -> { where(bytesize_changed: nil, hash_changed: nil) }
  scope :captured_new_tag_version, -> { where(captured_new_tag_version: true) }
end