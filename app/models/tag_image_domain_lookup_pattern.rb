class TagImageDomainLookupPattern < ApplicationRecord
  belongs_to :tag_image

  def self.find_and_apply_image_to_tag(tag)
    all.includes(:tag_image).each do |lookup_pattern|
      if lookup_pattern.matches?(tag.full_url)
        tag.update(tag_image: lookup_pattern.tag_image)
        return tag
      end
    end
  end

  def apply_image_to_tags_with_matching_pattern(override_existing_image = false)
    tags_matching_url_pattern = lookup_tags!
    tags_matching_url_pattern.each do |tag|
      tag.update!(tag_image: tag_image) if tag.tag_image.nil? || override_existing_image
    end
  end

  def lookup_tags!
    Tag.where('full_url LIKE ?', "%#{url_pattern}%")
  end

  def matches?(tag_url)
    tag_url.include?(url_pattern)
  end
end