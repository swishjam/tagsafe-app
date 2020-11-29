class Organization < ApplicationRecord
  has_many :users
  has_many :domains, dependent: :destroy
  has_many :created_tests, class_name: 'Test'
  has_many :script_subscriptions, through: :domains
  has_many :scripts, through: :domains

  accepts_nested_attributes_for :domains, :users

  def has_multiple_domains?
    domains.count > 1
  end
end