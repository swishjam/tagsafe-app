class PageChangeAudit < ApplicationRecord
  belongs_to :audit
  has_many :html_snapshots_without_tag, class_name: 'HtmlSnapshotWithoutTag', dependent: :destroy
  has_one :html_snapshot_with_tag, class_name: 'HtmlSnapshotWithTag', dependent: :destroy

  scope :tag_causes_page_changes, -> { where(tag_causes_page_changes: true) }
  scope :tag_doesnt_cause_page_changes, -> { where(tag_causes_page_changes: false) }
  scope :completed, -> { where.not(num_additions_between_without_tag_snapshots: nil) }
  scope :pending, -> { where(num_additions_between_without_tag_snapshots: nil) }

  # just take the first? it shouldn't matter which of the two we use...
  def html_snapshot_without_tag
    html_snapshots_without_tag.first
  end

  def completed?
    !num_additions_between_without_tag_snapshots.nil?
  end

  def pending?
    !completed?
  end

  def absolute_additions
    num_additions_between_with_tag_snapshot_without_tag_snapshot - num_additions_between_without_tag_snapshots
  end

  def absolute_deletions
    num_deletions_between_with_tag_snapshot_without_tag_snapshot - num_deletions_between_without_tag_snapshots
  end

  def absolute_changes
    absolute_additions + absolute_deletions
  end
end