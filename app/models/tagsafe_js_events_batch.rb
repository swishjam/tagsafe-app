class TagsafeJsEventsBatch < ApplicationRecord
  self.table_name = :tagsafe_js_events_batches
  belongs_to :domain
  has_many :tags, dependent: :destroy

  def previous_batch_for_domain
    domain.tagsafe_js_events_batches.most_recent_first.older_than(created_at).limit(1).first
  end
end