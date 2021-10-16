class CreatePageLoadTraces < ActiveRecord::Migration[6.1]
  def change
    create_table :page_load_traces do |t|
      t.string :uid
      t.string :s3_url
      t.references :performance_audit
    end
  end
end
