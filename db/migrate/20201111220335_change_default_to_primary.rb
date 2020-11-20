class ChangeDefaultToPrimary < ActiveRecord::Migration[5.2]
  def change
    rename_column :lighthouse_audits, :default, :primary
  end
end
