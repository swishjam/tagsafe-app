class Organization < ApplicationRecord
  has_many :users
  has_many :script_subscribers
  has_many :monitored_scripts, through: :script_subscribers
end