class CreatePerformanceAuditFilmstripTable < ActiveRecord::Migration[6.1]
  def change
    create_table :filmstrip_screenshots do |t|
      t.references :performance_audit
      t.string :uid, index: true
      t.integer :timestamp
    end
  end
end
