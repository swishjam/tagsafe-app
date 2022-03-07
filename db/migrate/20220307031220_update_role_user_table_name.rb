class UpdateRoleUserTableName < ActiveRecord::Migration[6.1]
  def up
    rename_table :roles_users, :domain_users_roles
  end
end
