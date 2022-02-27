class CreateHtmlSnapshots < ActiveRecord::Migration[6.1]
  def up
    create_table :html_snapshots do |t|
      t.string :uid, index: true
      t.references :audit
      t.string :type
      t.string :s3_file_location
      t.timestamp :enqueued_at
      t.timestamp :completed_at
    end
  end

  def down
    drop_table :html_snapshots
  end
end
