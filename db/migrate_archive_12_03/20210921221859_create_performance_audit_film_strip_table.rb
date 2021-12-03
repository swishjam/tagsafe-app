class CreatePerformanceAuditFilmStripTable < ActiveRecord::Migration[6.1]
  def change
    create_table :page_load_screenshots do |t|
      t.references :performance_audit
      t.string :s3_url
      t.integer :timestamp_ms
      t.integer :sequence
    end
  end
end
