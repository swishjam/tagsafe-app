class ScriptImage < ApplicationRecord
  has_one_attached :image
  has_many :lookup_patterns, class_name: 'ScriptImageDomainLookupPattern'
  has_many :scripts

  def self.apply_all_to_scripts(override_existing_image = false)
    all.map{ |script_image| script_image.apply_to_scripts(override_existing_image) }
  end

  def apply_to_scripts(override_existing_image = false)
    lookup_patterns.map { |pattern| pattern.apply_image_to_scripts_with_matching_pattern(override_existing_image) }
  end
end