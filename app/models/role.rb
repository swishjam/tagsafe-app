class Role < ApplicationRecord
  has_and_belongs_to_many :users

  def self.ADMIN
    @admin ||= find_by(name: 'admin')
  end
end