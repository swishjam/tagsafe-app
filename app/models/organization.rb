class Organization < ApplicationRecord
  has_many :users
  has_many :domains, dependent: :destroy
  has_many :created_tests, class_name: 'Test'
  has_many :scripts, through: :domains

  def has_multiple_domains?
    domains.count > 1
  end
end