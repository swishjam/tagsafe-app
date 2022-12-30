class CreatePageLoads < ActiveRecord::Migration[6.1]
  def change
    create_table :page_loads do |t|
      t.string :uid, index: true
      t.string :page_load_identifier, index: true
      t.references :container
      t.references :page_url
      t.string :cloudflare_message_id
      t.integer :num_tags_optimized_by_tagsafe_js
      t.integer :num_tags_not_optimized_by_tagsafe_js
      t.float :seconds_to_complete
      t.timestamp :page_load_ts
      t.timestamp :enqueued_at
      t.timestamp :tagsafe_consumer_received_at
      t.timestamp :tagsafe_consumer_processed_at
    end

    create_table :page_load_performance_metrics do |t|
      t.string :uid, index: true
      t.references :container
      t.references :page_load
      t.references :page_url
      t.string :type
      t.float :value
      t.timestamps
    end
    
    add_reference :tags, :page_load_found_on
  end
end
