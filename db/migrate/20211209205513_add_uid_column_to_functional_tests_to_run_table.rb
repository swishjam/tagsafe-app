class AddUidColumnToFunctionalTestsToRunTable < ActiveRecord::Migration[6.1]
  def up
    add_column :functional_tests_to_run, :uid, :string
    add_index :functional_tests_to_run, :uid
  end

  def down
    remove_column :functional_tests_to_run, :uid
  end
end
