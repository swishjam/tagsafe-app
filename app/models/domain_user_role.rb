class DomainUserRole < ApplicationRecord
  self.table_name = :domain_users_roles

  # belongs_to :user
  belongs_to :domain_user
  belongs_to :role
end