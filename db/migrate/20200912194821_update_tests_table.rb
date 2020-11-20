class UpdateTestsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :tests, :created_by_user_id, :integer
    add_column :tests, :default_test, :boolean, default: false
    add_column :tests, :created_by_organization_id,  :integer
  end
end
