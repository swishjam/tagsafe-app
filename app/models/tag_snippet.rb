class TagSnippet < ApplicationRecord
  uid_prefix 'tag_snip'
  VALID_STATES = %w[draft live paused deleted]

  attribute :state, default: 'draft'
  
  belongs_to :container
  has_many :tags, dependent: :destroy
  has_one_attached :content, service: :tag_snippet_contents_s3, dependent: :destroy

  validate :content_has_valid_script_tag_syntax
  validates :state, presence: true, inclusion: { in: VALID_STATES }

  after_update { container.publish_instrumentation! if saved_changes['state'].present? }
  after_create_commit :find_and_create_associated_tags_added_to_page_by_snippet

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

  def try_image_url
    return if tags.none?
    tags.first.try_image_url
  end

  def script_tags_attributes
    scripts = Nokogiri::HTML.fragment(content.download).css('script')
    scripts[0].attributes.map{ |name, attr| [name, attr.value] }
  end

  def executable_javascript
    scripts = Nokogiri::HTML.fragment(content.download).css('script')
    js = scripts[0].text.strip.gsub("'", '"')
    compiled_js = Uglifier.compile(js)
    compiled_js.blank? ? js.gsub("\n", "") : compiled_js
  end

  def downloaded_content
    content.download
  end

  def pending_find_tags_job?
    find_tags_injected_by_snippet_job_completed_at.nil?
  end

  def found_all_tags_injected_by_snippet!
    touch(:find_tags_injected_by_snippet_job_completed_at)
    broadcast_replace_to(
      "#{uid}_details_stream",
      target: "#{uid}_details",
      partial: 'tag_snippets/show',
      locals: { tag_snippet: self }
    )
  end

  private

  def find_and_create_associated_tags_added_to_page_by_snippet
    raise "TagSnippet already has associated Tags, delete Tags first before calling `find_and_create_associated_tags_added_to_page_by_snippet`" if tags.any?
    update!(find_tags_injected_by_snippet_job_enqueued_at: Time.current, find_tags_injected_by_snippet_job_completed_at: nil)
    FindTagsInSnippetJob.perform_later(self)
  end

  def content_has_valid_script_tag_syntax
    return unless attachment_changes["content"]
    temp_content = attachment_changes["content"].attachable[:io].read
    html = Nokogiri::HTML.fragment(temp_content)
    num_script_tags = html.css('script').count
    errors.add(:base, "Tag snippet must contain 1 (and only 1) script element.") unless num_script_tags == 1
  end
end