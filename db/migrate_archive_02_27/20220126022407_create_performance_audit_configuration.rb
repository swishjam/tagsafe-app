class CreatePerformanceAuditGeneralConfiguration < ActiveRecord::Migration[6.1]
  def change
    create_table :performance_audit_configurations do |t|
      t.string :uid, index: true
      t.references :audit
      t.integer :performance_audit_iterations
      t.boolean :strip_all_images
      t.boolean :include_page_tracing
      t.boolean :throw_error_if_dom_complete_is_zero
      t.boolean :inline_injected_script_tags
    end
  end
end
