class Event < ApplicationRecord
  include ContextualUid
  uid_prefix 'evt'
  acts_as_paranoid
  
  belongs_to :triggerer, polymorphic: true
end