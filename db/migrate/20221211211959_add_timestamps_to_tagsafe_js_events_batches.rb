class AddTimestampsToTagsafeJsEventsBatches < ActiveRecord::Migration[6.1]
  def change
    rename_table :tagsafe_js_events_batches, :tagsafe_js_event_batches
    add_column :tagsafe_js_event_batches, :tagsafe_js_ts, :timestamp
    add_column :tagsafe_js_event_batches, :enqueued_at, :timestamp
    add_column :tagsafe_js_event_batches, :tagsafe_consumer_received_at, :timestamp
    add_column :tagsafe_js_event_batches, :tagsafe_consumer_processed_at, :timestamp
    add_column :tagsafe_js_event_batches, :seconds_to_complete, :float

    rename_column :tags, :tagsafe_js_events_batch_id, :tagsafe_js_event_batch_id
    add_reference :tagsafe_js_event_batches, :page_url
  end
end
