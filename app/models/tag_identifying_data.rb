class TagIdentifyingData < ApplicationRecord
  self.table_name = :tag_identifying_data
  has_one_attached :image, service: :tag_image_s3
  has_many :tags
  has_many :tag_identifying_data_domains

  def self.for_tag(tag)
     split_domain = tag.url_domain.split('.')
     split_domain[0] = '*'
     domain_url_pattern_for_tag = split_domain.join('.')
    joins(:tag_identifying_data_domains).find_by("tag_identifying_data_domains.url_pattern = ? OR tag_identifying_data_domains.url_pattern = ?", tag.url_domain, domain_url_pattern_for_tag)
  end
end