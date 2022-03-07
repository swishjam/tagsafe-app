class MoveToDomainUsers < ActiveRecord::Migration[6.1]
  def up
    rename_table :organization_users, :domain_users
    rename_column :domain_users, :organization_id, :domain_id
    rename_column :user_invites, :organization_id, :domain_id
    rename_column :roles_users, :user_id, :domain_user_id
    remove_column :domains, :organization_id
  end
end
