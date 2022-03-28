class AddBytesToPerformanceAudits < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audits, :bytes, :integer
    add_column :delta_performance_audits, :bytes, :integer
    rename_column :tags, :content_changed_at, :last_released_at
  end

  def down
  end
end
