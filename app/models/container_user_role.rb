class ContainerUserRole < ApplicationRecord
  self.table_name = :container_users_roles

  # belongs_to :user
  belongs_to :container_user
  belongs_to :role
end