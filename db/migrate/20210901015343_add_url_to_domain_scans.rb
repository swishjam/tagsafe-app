class AddUrlToDomainScans < ActiveRecord::Migration[6.1]
  def change
    add_column :domain_scans, :url, :string
  end
end
