class User < ApplicationRecord
  has_secure_password

  belongs_to :organization

  validates :email, presence: true, uniqueness: true
end