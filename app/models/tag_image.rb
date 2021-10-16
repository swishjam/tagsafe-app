class TagImage < ApplicationRecord
  
  has_one_attached :image, service: :tag_image_s3
  has_many :lookup_patterns, class_name: 'TagImageDomainLookupPattern'
  has_many :tags

  def self.apply_all_to_tags(override_existing_image = false)
    all.map{ |tag_image| tag_image.apply_to_tags(override_existing_image) }
  end

  def apply_to_tags(override_existing_image = false)
    lookup_patterns.map { |pattern| pattern.apply_image_to_tags_with_matching_pattern(override_existing_image) }
  end
end