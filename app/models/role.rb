class Role < ApplicationRecord  
  uid_prefix 'role'

  has_many :roles_users, class_name: 'RoleUser'
  has_many :users, through: :roles_users
  # has_and_belongs_to_many :users

  def self.USER_ADMIN
    @user_admin ||= find_by(name: 'user_admin')
  end

  def self.TAGSAFE_ADMIN
    @tagsafe_admin ||= find_by(name: 'tagsafe_admin')
  end
  
  def apply_to(user)
    RoleUser.create!(role: self, user: user)
  end
  alias assign_to apply_to
end