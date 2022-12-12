class AddNewTagsIdentifiedBatch < ActiveRecord::Migration[6.1]
  def change
    create_table :tagsafe_js_event_batches do |t|
      t.string :uid, index: true
      t.string :cloudflare_message_id, index: true
      t.references :domain
      t.timestamps
    end

    create_table :tag_url_patterns_to_not_capture do |t|
      t.string :uid, index: true
      t.references :domain
      t.string :url_pattern
    end

    add_reference :tags, :tagsafe_js_events_batch
    add_column :tags, :last_seen_at, :datetime
    add_column :tags, :removed_from_site_at, :datetime
    add_column :domains, :tagsafe_js_reporting_sample_rate, :float
  end
end
