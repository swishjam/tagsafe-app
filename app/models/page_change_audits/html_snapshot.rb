class HtmlSnapshot < ApplicationRecord
  include HasExecutedLambdaFunction
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
    { bucket: TagsafeS3.url_to_bucket(html_s3_location), key: TagsafeS3.url_to_key(html_s3_location) }
  end

  def screenshot_s3_params
    { bucket: TagsafeS3.url_to_bucket(screenshot_s3_location), key: TagsafeS3.url_to_key(screenshot_s3_location) }
  end
end