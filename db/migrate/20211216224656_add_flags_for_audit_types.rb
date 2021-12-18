class AddFlagsForAuditTypes < ActiveRecord::Migration[6.1]
  def up
    add_column :audits, :include_page_load_resources, :boolean 
    add_column :audits, :include_page_change_audit, :boolean
    add_column :audits, :include_performance_audit, :boolean
    add_column :audits, :include_functional_tests, :boolean
  end

  def down
    remove_column :audits, :include_page_load_resources
    remove_column :audits, :include_page_change_audit
    remove_column :audits, :include_performance_audit
    remove_column :audits, :include_functional_tests
  end
end
