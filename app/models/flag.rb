class Flag < ApplicationRecord
  class Slugs
    class << self
      %w[
        display_tagsafe_score_confidence_range_indicator
      ].each do |slug|
        define_method(slug.upcase!) { slug }
      end
    end
  end
  uid_prefix 'flag'
  has_many :object_flags, dependent: :destroy

  class << self
    def find_by_slug!(slug)
      find_by!(slug: slug)
    rescue ActiveRecord::RecordNotFound => e
      raise FlagError::FlagDoesntExist, "Flag #{slug} does not exist, you must create the Flag to reference it in the application."
    end

    def find_object_flag(object, slug)
      ObjectFlag.find_by(flag: find_by_slug!(slug), object_id: object.id, object_type: object.class.to_s)
    end

    def set_flag_for_object(object, slug, value)
      existing_of = find_object_flag(object, slug)
      if existing_of
        existing_of.update!(value: value.to_s)
        existing_of
      else
        ObjectFlag.create!(flag: find_by_slug!(slug), value: value.to_s, object_id: object.id, object_type: object.class.to_s)
      end
    end

    def remove_flag_for_object(object, slug)
      of = find_object_flag(object, slug)
      of.destroy! if of
    end
  
    def flag_value(object, slug, fallback_to_default: true)
      of = find_object_flag(object, slug)
      of&.value || (fallback_to_default ? find_by(slug: slug).default_value : nil)
    end
  
    def flag_is_true(object, slug, fallback_to_default: true)
      flag_value(object, slug, fallback_to_default: fallback_to_default) == 'true'
    end
    alias flag_is_enabled flag_is_true

    def flag_is_true_for_objects(*objects, slug:)
      enabled_for_any_object = objects.any?{ |obj| flag_is_true(obj, slug, fallback_to_default: false) }
      return enabled_for_any_object || find_by_slug!(slug).default_value == 'true'
    end

    def flag_value_for_objects(*objects, slug:)
      value = nil
      objects.each do |obj| 
        value = flag_value(obj, slug, fallback_to_default: false)
        break if value
      end
      return value || find_by_slug!(slug).default_value
    end
  end
end