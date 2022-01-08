class PuppeteerRecording < ApplicationRecord
  uid_prefix 'pup_rec'
  belongs_to :initiator, polymorphic: true

  before_destroy :purge_from_s3

  validates_presence_of :s3_url

  FAILED_TO_CAPTURE_S3_URL_VALUE = 'FAILED_TO_CAPTURE'.freeze

  def fetch_recording
    unless failed_to_capture?
      @recording ||= TagsafeS3.client.get_object(s3_client_params).body.read
    end
  end

  def purge_from_s3
    unless failed_to_capture?
      TagsafeS3.client.delete_object(s3_client_params)
    end
  end

  def failed_to_capture?
    s3_url == FAILED_TO_CAPTURE_S3_URL_VALUE
  end

  def captured_successfully?
    s3_url && !failed_to_capture?
  end

  private

  def s3_client_params
    { bucket: TagsafeS3.url_to_bucket(s3_url), key: TagsafeS3.url_to_key(s3_url) }
  end
end