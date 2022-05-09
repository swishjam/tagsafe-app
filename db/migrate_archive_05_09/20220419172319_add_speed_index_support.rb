class AddSpeedIndexSupport < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audits, :speed_index, :float
    add_column :performance_audits, :perceptual_speed_index, :float
    add_column :performance_audits, :ms_until_first_visual_change, :float
    add_column :performance_audits, :ms_until_last_visual_change, :float

    add_column :delta_performance_audits, :speed_index_delta, :float
    add_column :delta_performance_audits, :perceptual_speed_index_delta, :float
    add_column :delta_performance_audits, :ms_until_first_visual_change_delta, :float
    add_column :delta_performance_audits, :ms_until_last_visual_change_delta, :float

    create_table :performance_audit_speed_index_frames do |t|
      t.string :uid, index: true
      t.references :performance_audit, index: { name: :index_pasif_on_performance_audit_id }
      t.string :s3_url
      t.float :ms_from_start
      t.float :ts
      t.float :progress
      t.float :perceptual_progress
    end
  end

  def down
    remove_column :performance_audits, :speed_index
    remove_column :performance_audits, :perceptual_speed_index
    remove_column :performance_audits, :ms_until_first_visual_change
    remove_column :performance_audits, :ms_until_last_visual_change

    remove_column :delta_performance_audits, :speed_index_delta
    remove_column :delta_performance_audits, :perceptual_speed_index_delta
    remove_column :delta_performance_audits, :ms_until_first_visual_change_delta
    remove_column :delta_performance_audits, :ms_until_last_visual_change_delta

    drop_table :performance_audit_speed_index_frames
  end
end
