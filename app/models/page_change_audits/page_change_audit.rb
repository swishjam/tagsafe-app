class PageChangeAudit < ApplicationRecord
  belongs_to :audit
  has_many :html_snapshots_without_tag, class_name: 'HtmlSnapshotWithoutTag', dependent: :destroy
  has_one :html_snapshot_with_tag, class_name: 'HtmlSnapshotWithTag', dependent: :destroy

  scope :tag_causes_page_changes, -> { where(tag_causes_page_changes: true) }
  scope :tag_doesnt_cause_page_changes, -> { where(tag_causes_page_changes: false) }
  scope :completed, -> { where.not(num_additions_between_without_tag_snapshots: nil) }
  scope :pending, -> { where(num_additions_between_without_tag_snapshots: nil) }

  after_create :set_initial_html_content

  INITIAL_HTML_CONTENT_S3_BUCKET = "html-snapshotter-files-#{Rails.env}".freeze

  # just take the first? it shouldn't matter which of the two we use...
  def html_snapshot_without_tag
    html_snapshots_without_tag.first
  end

  def completed!
    TagsafeS3.client.delete_object({ bucket: INITIAL_HTML_CONTENT_S3_BUCKET, key: initial_html_content_s3_key })
    update!(initial_html_content_s3_url: 'PURGED')
    audit.page_change_audit_completed!
  end

  def failed!(msg)
    update!(error_message: msg)
    completed!
  end

  def completed_successfully?
    completed? && !failed?
  end

  def completed?
    !num_additions_between_without_tag_snapshots.nil?
  end

  def pending?
    !completed?
  end

  def failed?
    !error_message.nil?
  end

  def absolute_additions
    return unless completed?
    num_additions_between_with_tag_snapshot_without_tag_snapshot - num_additions_between_without_tag_snapshots
  end

  def absolute_deletions
    return unless completed?
    num_deletions_between_with_tag_snapshot_without_tag_snapshot - num_deletions_between_without_tag_snapshots
  end

  def absolute_changes
    return unless completed?
    absolute_additions + absolute_deletions
  end

  def initial_html_content_s3_key
    TagsafeS3.url_to_key(initial_html_content_s3_url)
  end

  private

  def set_initial_html_content
    response = HTTParty.get(audit.page_url.full_url, headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0' })
    raise StandardError, "Unable to set initial HTML content, #{audit.page_url.full_url} request was unsuccessful" unless response.success?
    s3_obj = TagsafeS3.client.put_object({ bucket: INITIAL_HTML_CONTENT_S3_BUCKET, key: assumed_initial_html_content_s3_key, body: response.body })
    update!(initial_html_content_s3_url: "https://#{INITIAL_HTML_CONTENT_S3_BUCKET}.s3.amazonaws.com/#{assumed_initial_html_content_s3_key}")
  end

  def assumed_initial_html_content_s3_key
    "#{uid}-initial-html-content.html"
  end
end