class NewTagsIdentifiedBatch < ApplicationRecord
  self.table_name = :new_tags_identified_batches
  belongs_to :domain
  has_many :tags

  def previous_batch_for_domain
    domain.new_tags_identified_batches.most_recent_first.older_than(created_at).limit(1).first
  end
end