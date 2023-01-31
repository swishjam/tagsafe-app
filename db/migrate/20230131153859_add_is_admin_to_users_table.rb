class AddIsAdminToUsersTable < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_tagsafe_admin, :boolean, default: false
  end
end
