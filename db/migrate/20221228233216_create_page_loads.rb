class CreatePageLoads < ActiveRecord::Migration[6.1]
  def change
    create_table :page_loads do |t|
      t.string :uid, index: true
      t.references :page_url
      t.string :cloudflare_message_id
      t.float :dom_complete_ms
      t.float :dom_interactive_ms
      t.float :seconds_to_complete
      t.timestamp :tagsafe_js_ts
      t.timestamp :enqueued_at
      t.timestamp :tagsafe_consumer_received_at
      t.timestamp :tagsafe_consumer_processed_at
    end
  end
end
