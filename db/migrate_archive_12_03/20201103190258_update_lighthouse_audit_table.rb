class UpdateLighthouseAuditTable < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audits, :audited_url, :string
    remove_column :lighthouse_audits, :created_at
    remove_column :lighthouse_audits, :updated_at
  end
end
