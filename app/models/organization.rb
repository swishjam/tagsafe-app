class Organization < ApplicationRecord
  has_many :organization_users
  has_many :users, through: :organization_users
  has_many :domains, dependent: :destroy
  has_many :created_tests, class_name: 'Test'
  has_many :script_subscriptions, through: :domains
  has_many :scripts, through: :domains

  accepts_nested_attributes_for :domains, :organization_users

  def has_multiple_domains?
    domains.count > 1
  end

  def add_user(user)
    users << user
  end

  def remove_user(user)
    if ou = organization_users.find_by(user_id: user.id)
      ou.destroy!
    end
  end
end