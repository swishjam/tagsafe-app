class AddReleaseCheckAndUptimeCheckBatches < ActiveRecord::Migration[6.1]
  def up
    create_table :uptime_check_batches do |t|
      t.string :uid, index: true
      t.string :batch_uid, index: true
      t.references :uptime_region
      t.integer :num_tags_checked
      t.datetime :executed_at
      t.datetime :processing_completed_at
      t.float :ms_to_run_check
    end

    create_table :release_check_batches do |t|
      t.string :uid, index: true
      t.string :batch_uid, index: true
      t.string :minute_interval
      t.integer :num_tags_with_new_versions
      t.integer :num_tags_without_new_versions
      t.datetime :executed_at
      t.datetime :processing_completed_at
      t.float :ms_to_run_check
    end

    add_reference :release_checks, :release_check_batch
    add_reference :uptime_checks, :uptime_check_batch
  end

  def down
    drop_table :uptime_check_batches
    drop_table :release_check_batches
    remove_reference :release_checks, :release_check_batch
    remove_reference :uptime_checks, :uptime_check_batch
  end
end
