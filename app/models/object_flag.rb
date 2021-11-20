class ObjectFlag < ApplicationRecord
  belongs_to :flag
  belongs_to :object, polymorphic: true
end