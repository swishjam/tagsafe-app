class AddPerformanceAuditCalculators < ActiveRecord::Migration[6.1]
  def up
    create_table :performance_audit_calculators do |t|
      t.string :uid
      t.references :domain
      t.boolean :currently_active
      
      t.float :dom_complete_weight
      t.float :dom_content_loaded_weight
      t.float :dom_interactive_weight
      t.float :first_contentful_paint_weight
      t.float :layout_duration_weight
      t.float :task_duration_weight
      t.float :script_duration_weight
      t.float :byte_size_weight

      t.integer :dom_complete_score_decrement_amount
      t.integer :dom_content_loaded_score_decrement_amount
      t.integer :dom_interactive_score_decrement_amount
      t.integer :first_contentful_paint_score_decrement_amount
      t.integer :layout_duration_score_decrement_amount
      t.integer :task_duration_score_decrement_amount
      t.integer :script_duration_score_decrement_amount
      t.integer :byte_size_score_decrement_amount
    end
    
    add_column :domains, :current_performance_audit_calculator_id, :integer
    add_index :domains, :current_performance_audit_calculator_id

    add_column :audits, :peformance_audit_calculator_id, :integer
    add_index :audits, :peformance_audit_calculator_id
  end

  def down
    drop_table :performance_audit_calculators
    remove_column :domains, :current_performance_audit_calculator_id
    # remove_index :domains, :current_performance_audit_calculator_id
    
    remove_column :audits, :peformance_audit_calculator_id
    # remove_index :audits, :peformance_audit_calculator_id
  end
end
