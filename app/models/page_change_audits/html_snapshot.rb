class HtmlSnapshot < ApplicationRecord
  belongs_to :page_change_audit

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }

  before_destroy :purge_s3_files

  def fetch_html_content
    if html_s3_location
      @html_content ||= TagsafeS3.client.get_object(html_s3_params).body.read
    end
  end

  def fetch_screenshot
    if screenshot_s3_location
      @screenshot ||= TagsafeS3.client.get_object(screenshot_s3_params).body.read
    end
  end

  def purge_s3_files
    TagsafeS3.client.delete_object(html_s3_params) if html_s3_location
    TagsafeS3.client.delete_object(screenshot_s3_params) if screenshot_s3_location
    update!(html_s3_location: nil, screenshot_s3_location: nil)
  end

  def completed?
    !completed_at.nil?
  end

  def pending?
    !completed?
  end

  private

  def html_s3_params
    { bucket: s3_bucket_name, key: TagsafeS3.url_to_key(html_s3_location) }
  end

  def screenshot_s3_params
    { bucket: s3_bucket_name, key: TagsafeS3.url_to_key(screenshot_s3_location) }
  end

  def s3_bucket_name
    case Rails.env
    when 'development'
      'dev-tagsafe-html-snapshots'
    when 'production'
      'prod-tagsafe-html-snapshots'
    end
  end
end