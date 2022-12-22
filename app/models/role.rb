class Role < ApplicationRecord
  uid_prefix 'role'

  has_many :container_user_role, class_name: ContainerUserRole.to_s
  has_many :users, through: :roles_users

  def self.USER_ADMIN
    @user_admin ||= find_by(name: 'user_admin')
  end

  def self.TAGSAFE_ADMIN
    @tagsafe_admin ||= find_by(name: 'tagsafe_admin')
  end
  
  def apply_to_container_user(container_user)
    ContainerUserRole.create!(role: self, container_user: container_user)
  end
end