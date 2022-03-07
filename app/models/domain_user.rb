class DomainUser < ApplicationRecord
  belongs_to :user
  belongs_to :domain
  has_many :domain_user_roles, class_name: DomainUserRole.to_s
end