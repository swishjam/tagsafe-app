class TagsafeJsEventBatch < ApplicationRecord
  self.table_name = :tagsafe_js_event_batches
  belongs_to :container
  belongs_to :page_url
  has_many :tags, dependent: :destroy

  before_create { self.tagsafe_consumer_received_at = Time.current }

  def processing_completed!
    raise "Cannot mark TagsafeJsEventBatch processing complete, `tagsafe_js_ts` is nil." if tagsafe_js_ts.nil?
    raise "Cannot mark TagsafeJsEventBatch processing complete, `enqueued_at` is nil." if enqueued_at.nil?
    raise "Cannot mark TagsafeJsEventBatch processing complete, `tagsafe_consumer_received_at` is nil." if tagsafe_consumer_received_at.nil?
    update!(tagsafe_consumer_processed_at: Time.current, seconds_to_complete: Time.current - tagsafe_js_ts)
  end
end