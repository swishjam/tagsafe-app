class CreateDomainUrlsToScan < ActiveRecord::Migration[6.1]
  def change
    create_table :urls_to_scans do |t|
      t.references :domain
      t.string :url
      t.timestamps
    end

    create_table :urls_to_audits do |t|
      t.references :tags
      t.string :url
      t.timestamps
    end
  end
end
