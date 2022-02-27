class AddCachedResponsesS3UrlToAudit < ActiveRecord::Migration[6.1]
  def up
    add_column :audits, :performance_audit_cached_responses_s3_url, :string
  end

  def down
    remove_column :audits, :performance_audit_cached_responses_s3_url
  end
end
