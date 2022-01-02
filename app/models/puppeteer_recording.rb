class PuppeteerRecording < ApplicationRecord
  uid_prefix 'pup_rec'
  belongs_to :initiator, polymorphic: true

  before_destroy :purge_from_s3

  validates_presence_of :s3_url

  def fetch_recording
    @recording ||= TagsafeS3.client.get_object(s3_client_params).body.read
  end

  def purge_from_s3
    TagsafeS3.client.delete_object(s3_client_params)
  end

  private

  def s3_client_params
    { bucket: TagsafeS3.url_to_bucket(s3_url), key: TagsafeS3.url_to_key(s3_url) }
  end
end