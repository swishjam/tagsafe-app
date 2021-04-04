class CreateTagAllowedPerformanceAuditTags < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_allowed_performance_audit_third_party_urls do |t|
      t.integer :performance_audit_tag_id
      t.integer :allowed_tag_id
    end
  end
end
