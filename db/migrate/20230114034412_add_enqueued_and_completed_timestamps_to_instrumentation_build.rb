class AddEnqueuedAndCompletedTimestampsToInstrumentationBuild < ActiveRecord::Migration[6.1]
  def change
    add_column :instrumentation_builds, :enqueued_at, :timestamp
    add_column :instrumentation_builds, :completed_at, :timestamp
  end
end
