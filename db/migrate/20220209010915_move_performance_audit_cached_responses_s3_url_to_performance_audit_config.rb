class MovePerformanceAuditCachedResponsesS3UrlToPerformanceAuditConfig < ActiveRecord::Migration[6.1]
  def change
    remove_column :audits, :performance_audit_cached_responses_s3_url
    add_column :performance_audit_configurations, :cached_responses_s3_url, :string
  end
end
