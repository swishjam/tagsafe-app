class ChangeOrganizationUserRelationship < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_users do |t|
      t.integer :user_id
      t.integer :organization_id
    end

    remove_column :users, :organization_id
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
