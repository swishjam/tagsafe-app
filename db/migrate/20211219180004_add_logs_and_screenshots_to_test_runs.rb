class AddLogsAndScreenshotsToTestRuns < ActiveRecord::Migration[6.1]
  def up
    add_column :test_runs, :logs, :mediumtext
    create_table :test_run_screenshots do |t|
      t.string :uid, index: true
      t.references :test_run
      t.string :name
      t.string :s3_url
      t.integer :timestamp
    end
    add_column :test_runs, :puppeteer_script_ran, :text
    add_column :test_runs, :expected_results, :string
    add_column :functional_tests, :disabled_at, :timestamp
    add_reference :test_runs, :test_run_without_tag
  end

  def down
    remove_column :test_runs, :logs
    drop_table :test_run_screenshots
    remove_column :test_runs, :expected_results
    remove_column :test_runs, :puppeteer_script_ran
    remove_column :functional_tests, :disabled_at
    remove_reference :test_runs, :test_run_without_tag
  end
end
