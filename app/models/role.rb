class Role < ApplicationRecord
  uid_prefix 'role'

  has_many :domain_user_role, class_name: DomainUserRole.to_s
  has_many :users, through: :roles_users

  def self.USER_ADMIN
    @user_admin ||= find_by(name: 'user_admin')
  end

  def self.TAGSAFE_ADMIN
    @tagsafe_admin ||= find_by(name: 'tagsafe_admin')
  end
  
  def apply_to_domain_user(domain_user)
    DomainUserRole.create!(role: self, domain_user: domain_user)
  end
end