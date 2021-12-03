class CreateGepettoJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :gepetto_jobs do |t|
      t.references :job_intitiator, polymorphic: true
      t.references :organization
      t.timestamp :began_at
      t.timestamp :completed_at
    end
  end
end
