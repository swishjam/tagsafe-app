class AddNewTagsIdentifiedBatch < ActiveRecord::Migration[6.1]
  def change
    create_table :new_tags_identified_batches do |t|
      t.string :uid, index: true
      t.string :cloudflare_message_id, index: true
      t.references :domain
      t.timestamps
    end

    add_reference :tags, :new_tags_identified_batch

    create_table :tag_url_patterns_to_not_capture do |t|
      t.string :uid, index: true
      t.references :domain
      t.string :url_pattern
    end

    add_column :tags, :last_seen_at, :datetime
    add_column :tags, :removed_from_site_at, :datetime
  end
end
