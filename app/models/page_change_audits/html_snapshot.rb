class HtmlSnapshot < ApplicationRecord
  belongs_to :page_change_audit

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }

  before_destroy :purge_s3_files

  def fetch_html_content
    if html_s3_location
      @html_content ||= _s3_client.get_object({ bucket: s3_bucket_name, key: s3_filename_for(html_s3_location) }).body.read
    end
  end

  def fetch_screenshot
    if screenshot_s3_location
      @screenshot ||= _s3_client.get_object({ bucket: s3_bucket_name, key: s3_filename_for(screenshot_s3_location) }).body.read
    end
  end

  def purge_s3_files
    _s3_client.delete_object({ bucket: s3_bucket_name, key: s3_filename_for(html_s3_location) }) if html_s3_location
    _s3_client.delete_object({ bucket: s3_bucket_name, key: s3_filename_for(screenshot_s3_location) }) if screenshot_s3_location
    update!(html_s3_location: nil, screenshot_s3_location: nil)
  end

  def completed?
    !completed_at.nil?
  end

  def pending?
    !completed?
  end

  private

  def s3_filename_for(s3_url)
    URI.parse(s3_url).path.gsub('/', '')
  end

  def s3_bucket_name
    case Rails.env
    when 'development'
      'dev-tagsafe-html-snapshots'
    when 'production'
      'prod-tagsafe-html-snapshots'
    end
  end

  def _s3_client
    @_s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: 'us-east-1'
    )
  end
end