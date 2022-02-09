class PerformanceAuditConfiguration < ApplicationRecord
  belongs_to :audit

  def cached_responses_s3_key
    cached_responses_s3_url ? TagsafeS3.url_to_key(cached_responses_s3_url) : nil
  end
end
