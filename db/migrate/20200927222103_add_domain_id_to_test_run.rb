class AddDomainIdToTestRun < ActiveRecord::Migration[5.2]
  def change
    add_column :test_runs, :standalone_test_run_domain_id, :integer
  end
end
