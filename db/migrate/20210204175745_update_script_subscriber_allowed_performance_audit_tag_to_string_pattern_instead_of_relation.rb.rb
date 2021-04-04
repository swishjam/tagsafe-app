class UpdateTagAllowedPerformanceAuditTagToStringPatternInsteadOfRelation < ActiveRecord::Migration[5.2]
  def change
    remove_column :tag_allowed_performance_audit_third_party_urls, :allowed_tag_id
    add_column :tag_allowed_performance_audit_third_party_urls, :url_pattern, :string
    rename_column :tag_allowed_performance_audit_third_party_urls, :performance_audit_tag_id, :tag_id
  end
end
