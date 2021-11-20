class CreateBlockedResources < ActiveRecord::Migration[6.1]
  def change
    create_table :blocked_resources do |t|
      t.string :uid
      t.references :performance_audit
      t.text :url
      t.string :resource_type
      t.timestamps
    end
  end
end
