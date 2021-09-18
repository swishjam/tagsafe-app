class OrganizationUser < ApplicationRecord
  uid_prefix 'orgu'
  belongs_to :user
  belongs_to :organization
end