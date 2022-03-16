class HtmlSnapshot < ApplicationRecord
  include HasExecutedLambdaFunction
  belongs_to :page_change_audit

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }

  before_destroy :purge_s3_files

  def fetch_html_content
    if html_s3_location
      @html_content ||= TagsafeAws::S3.get_object_by_s3_url(html_s3_location).body.read
    end
  end

  def fetch_screenshot
    if screenshot_s3_location
      @screenshot ||= TagsafeAws::S3.get_object_by_s3_url(screenshot_s3_location).body.read
    end
  end

  def purge_s3_files
    TagsafeAws::S3.delete_object_by_s3_url(html_s3_location) if html_s3_location
    TagsafeAws::S3.delete_object_by_s3_url(screenshot_s3_location) if screenshot_s3_location
    update!(html_s3_location: nil, screenshot_s3_location: nil)
  end

  def completed?
    !completed_at.nil?
  end

  def pending?
    !completed?
  end
end