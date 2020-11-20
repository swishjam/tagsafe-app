class AddEnqueueTimestamps < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audits, :enqueued_at, :timestamp
    add_column :lighthouse_audits, :completed_at, :timestamp

    add_column :test_group_runs, :enqueued_at, :timestamp
    add_column :test_group_runs, :completed_at, :timestamp
  end
end
