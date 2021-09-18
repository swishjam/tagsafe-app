class Role < ApplicationRecord
  
  uid_prefix 'role'

  has_and_belongs_to_many :users

  def self.USER_ADMIN
    @user_admin ||= find_by(name: 'user_admin')
  end

  def self.TAGSAFE_ADMIN
    @tagsafe_admin ||= find_by(name: 'tagsafe_admin')
  end
end