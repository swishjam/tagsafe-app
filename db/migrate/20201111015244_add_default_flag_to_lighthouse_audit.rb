class AddDefaultFlagToLighthouseAudit < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audits, :default, :boolean
  end
end
