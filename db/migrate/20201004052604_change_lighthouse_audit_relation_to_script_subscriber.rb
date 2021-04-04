class ChangeLighthouseAuditRelationToTag < ActiveRecord::Migration[5.2]
  def change
    remove_column :lighthouse_audits, :domain_id
    remove_column :lighthouse_audits, :script_id
    add_column :lighthouse_audits, :tag_id, :integer
  end
end
