class AddEnqueuedAtCompletedAtTimestamps < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audits, :enqueued_at, :timestamp
    add_column :performance_audits, :completed_at, :timestamp

    rename_column :url_crawls, :enqueued_at, :enqueued_at
    rename_column :url_crawls, :completed_at, :completed_at

    rename_column :audits, :enqueued_at, :enqueued_at
    add_column :audits, :completed_at, :timestamp
  end
end
