class CreatePuppeteerRecordings < ActiveRecord::Migration[6.1]
  def up
    create_table :puppeteer_recordings do |t|
      t.string :uid, index: true
      t.references :initiator, polymorphic: true
      t.string :s3_url
      t.integer :ms_to_stop_recording
      t.datetime :created_at, null: false
    end
  end

  def down
    drop_table :puppeteer_recordings
  end
end
