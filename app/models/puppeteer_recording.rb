class PuppeteerRecording < ApplicationRecord
  uid_prefix 'pup_rec'
  belongs_to :initiator, polymorphic: true

  before_destroy { purge_from_s3(false) }

  validates_presence_of :s3_url

  FAILED_TO_CAPTURE_S3_URL_VALUE = 'FAILED_TO_CAPTURE'.freeze
  PURGED_S3_URL_VALUE = 'PURGED'.freeze

  def fetch_recording
    unless failed_to_capture? || purged?
      @recording ||= TagsafeAws::S3.client.get_object(s3_client_params).body.read
    end
  end

  def purge_from_s3(update_url_value = true)
    unless failed_to_capture? || purged?
      TagsafeAws::S3.client.delete_object(s3_client_params)
      update!(s3_url: PURGED_S3_URL_VALUE) if update_url_value
    end
  end

  def failed_to_capture?
    s3_url == FAILED_TO_CAPTURE_S3_URL_VALUE
  end

  def purged?
    s3_url == PURGED_S3_URL_VALUE
  end

  def captured_successfully?
    s3_url && !failed_to_capture? && !purged?
  end

  private

  def s3_client_params
    { bucket: TagsafeAws::S3.url_to_bucket(s3_url), key: TagsafeAws::S3.url_to_key(s3_url) }
  end
end