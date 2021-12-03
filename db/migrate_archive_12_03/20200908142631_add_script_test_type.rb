class AddTagTestType < ActiveRecord::Migration[5.2]
  def change
    create_table :script_test_types do |t|
      t.string :name
    end

    add_column :test_runs, :script_test_type, :integer
  end
end
