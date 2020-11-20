class CreateScriptChecks < ActiveRecord::Migration[5.2]
  def change
    create_table :script_check_region do |t|
      t.string :name
    end

    create_table :script_checks do |t|
      t.integer :script_id
      t.integer :script_check_region_id
      t.float :response_time_ms
      t.integer :response_code
      t.timestamp :created_at, default: "CURRENT_TIMESTAMP"
    end

    add_column :scripts, :should_log_script_checks, :boolean
  end
end
