class RemoveGeppettoJobs < ActiveRecord::Migration[5.2]
  def change
    drop_table :geppetto_jobs
  end
end
