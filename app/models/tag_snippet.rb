class TagSnippet < ApplicationRecord
  uid_prefix 'tag_snip'
  VALID_STATES = %w[draft live paused deleted]

  attribute :state, default: 'default'
  
  belongs_to :container
  has_many :tags
  has_one_attached :content, service: :tag_snippet_contents_s3

  validate :content_has_valid_script_tag_syntax
  validates :state, presence: true, inclusion: { in: VALID_STATES }

  TagSnippet::VALID_STATES.each do |state|
    define_method(:"#{state}?") { self.state == state }
    define_method(:"#{state}!") { self.update!(state: state) }
  end

  class << self
    TagSnippet::VALID_STATES.each do |state|
      define_method(:"in_#{state}_state") { where(state: state) }
    end
  end

  def try_friendly_name
    return if tags.none?
    tags.first.friendly_name
  end

  def html_content
    content
  end

  def js_content
    html = downloaded_content
    leading_script_tag_stripped = html.gsub(/<script[^>]*\>/, "")
    leading_script_tag_stripped.gsub(/<\/script[^>]*\>/, "")
  end

  def downloaded_content
    content.download
  end

  def find_and_create_associated_tags_added_to_page_by_snippet
    raise "TagSnippet already has associated Tags, delete Tags first before calling `find_and_create_associated_tags_added_to_page_by_snippet`" if tags.any?
    tag_data = TagManager::FindTagsInTagSnippet.find!(js_content)
    tag_data.each do |tag_data|
      tags.create!(container: container, full_url: tag_data['url'], load_type: tag_data['load_type'])
    end
  end

  private

  def content_has_valid_script_tag_syntax
    # TODO
  end
end