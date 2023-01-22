class TagSnippet < ApplicationRecord
  uid_prefix 'tag_snip'
  VALID_STATES = %w[draft live paused deleted]

  attribute :state, default: 'draft'
  
  belongs_to :container
  has_many :tags, dependent: :destroy
  has_one_attached :content, service: :tag_snippet_contents_s3, dependent: :destroy

  validates :state, presence: true, inclusion: { in: VALID_STATES }

  after_update { container.publish_instrumentation!("Updating for #{name} updated state (#{saved_changes['state'][0]} -> #{saved_changes['state'][1]})") if saved_changes['state'].present? }
  # after_create_commit :find_and_create_associated_tags_added_to_page_by_snippet

  TagSnippet::VALID_STATES.each do |state|
    define_method(:"#{state}?") { self.state == state }
    define_method(:"#{state}!") { self.update!(state: state) }
  end

  class << self
    TagSnippet::VALID_STATES.each do |state|
      define_method(:"#{state}") { where(state: state) }
      define_method(:"in_#{state}_state") { where(state: state) }
      define_method(:"not_#{state}") { where.not(state: state) }
      define_method(:"not_in_#{state}_state") { where.not(state: state) }
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

  def encoded_content
    Base64.encode64(downloaded_content).gsub("\n", "")
  end

  def downloaded_content
    content.download
  end

  def pending_find_tags_job?
    find_tags_injected_by_snippet_job_completed_at.nil?
  end

  def found_all_tags_injected_by_snippet!
    touch(:find_tags_injected_by_snippet_job_completed_at)
    update_tag_snippet_details_view
  end

  def update_tag_snippet_details_view
    broadcast_replace_to(
      "#{uid}_details_stream",
      target: "#{uid}_details",
      partial: 'tag_snippets/show',
      locals: { 
        tag_snippet: self,
        container: container,
      }
    )
  end

  private

  # def find_and_create_associated_tags_added_to_page_by_snippet
  #   raise "TagSnippet already has associated Tags, delete Tags first before calling `find_and_create_associated_tags_added_to_page_by_snippet`" if tags.any?
  #   update!(find_tags_injected_by_snippet_job_enqueued_at: Time.current, find_tags_injected_by_snippet_job_completed_at: nil)
  #   FindAndCreateTagsForTagSnippetJob.perform_later(self)
  # end
end