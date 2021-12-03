class FixGepettoJobTypo < ActiveRecord::Migration[5.2]
  def change
    rename_column :gepetto_jobs, :job_intitiator_type, :job_initiator_type
    rename_column :gepetto_jobs, :job_intitiator_id, :job_initiator_id
  end
end
