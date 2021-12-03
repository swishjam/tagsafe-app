class CreateDomainScans < ActiveRecord::Migration[5.2]
  def up
    create_table :url_crawls do |t|
      t.integer :domain_id
      t.datetime :enqueued_at
      t.datetime :completed_at
      t.text :error_message
    end
  end

  def down
    drop_table :url_crawls
  end
end
