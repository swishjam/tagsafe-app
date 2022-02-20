class PerformanceAuditConfiguration < ApplicationRecord
  belongs_to :audit

  after_destroy_commit :purge_cached_response_s3_url_if_necessary

  def cached_responses_s3_key
    return if cached_responses_s3_url.nil? || cached_responses_s3_url == 'PURGED'
    cached_responses_s3_url ? TagsafeS3.url_to_key(cached_responses_s3_url) : nil
  end

  def purge_cached_response_s3_url_if_necessary
    return if cached_responses_s3_url.nil? || cached_responses_s3_url == 'PURGED'
    TagsafeS3.delete_object_by_s3_url(cached_responses_s3_url)
    update!(cached_responses_s3_url: 'PURGED')
  end
end
