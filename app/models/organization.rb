class Organization < ApplicationRecord
  has_many :users
  # has_many :monitored_scripts_organizations
  has_and_belongs_to_many :monitored_scripts

  def add_monitored_script(script)
    monitored_scripts << script
  end
end