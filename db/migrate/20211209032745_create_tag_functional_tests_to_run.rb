class CreateTagFunctionalTestsToRun < ActiveRecord::Migration[6.1]
  def up
    create_table :functional_tests_to_run do |t|
      t.references :tag
      t.references :functional_test
      t.timestamps
    end

    add_column :functional_tests, :run_on_all_tags, :boolean
  end

  def down
    drop_table :functional_tests_to_run
    remove_column :functional_test, :run_on_all_tags
  end
end
