class PerformanceAuditSpeedIndexFrame < ApplicationRecord
  belongs_to :performance_audit

  before_destroy :purge_s3_file

  def purge_s3_file
    TagsafeAws::S3.delete_object_by_s3_url(s3_url)
  end
end