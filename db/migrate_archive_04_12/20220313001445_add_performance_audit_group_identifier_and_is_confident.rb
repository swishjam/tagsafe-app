class AddPerformanceAuditGroupIdentifierAndIsConfident < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audits, :batch_identifier, :string, index: true
    add_column :audits, :tagsafe_score_is_confident, :boolean
    remove_column :performance_audits, :audit_performed_with_tag
  end
end
