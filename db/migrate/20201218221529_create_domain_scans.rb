class CreateDomainScans < ActiveRecord::Migration[5.2]
  def up
    create_table :domain_scans do |t|
      t.integer :domain_id
      t.datetime :scan_enqueued_at
      t.datetime :scan_completed_at
      t.text :error_message
    end
  end

  def down
    drop_table :domain_scans
  end
end