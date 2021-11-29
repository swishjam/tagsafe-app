class ObjectFlag < ApplicationRecord
  belongs_to :flag
  belongs_to :object, polymorphic: true

  def display_name
    case object_type
    when 'Organization'
      "#{object.name} (Organization)"
    when 'Domain'
      "#{object.url} (Domain)"
    when 'Tag'
      "#{object.try_friendly_name} (Tag)"
    end
  end
end