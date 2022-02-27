class CreateFunctionalTestsAndTestRuns < ActiveRecord::Migration[6.1]
  def up
    create_table :functional_tests do |t|
      t.string :uid, index: true
      t.references :domain
      t.references :created_by_user
      t.string :title
      t.string :description
      t.text :puppeteer_script
      t.string :expected_results

      t.timestamps
    end

    create_table :test_runs do |t|
      t.string :uid, index: true
      t.references :functional_test
      t.references :audit
      t.string :type
      t.string :results
      t.boolean :passed
      # t.boolean :is_dry_run

      t.timestamp :enqueued_at
      t.timestamp :completed_at
    end
  end

  def down
    drop_table :functional_tests
    drop_table :test_runs
  end
end
