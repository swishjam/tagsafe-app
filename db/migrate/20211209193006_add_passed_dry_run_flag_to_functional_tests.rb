class AddPassedDryRunFlagToFunctionalTests < ActiveRecord::Migration[6.1]
  def up
    add_column :functional_tests, :passed_dry_run, :boolean
  end

  def down
    remove_column :functional_tests, :passed_dry_run
  end
end
