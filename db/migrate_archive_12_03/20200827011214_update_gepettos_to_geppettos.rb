class UpdateGepettosToGeppettos < ActiveRecord::Migration[5.2]
  def change
    rename_table :gepetto_jobs, :geppetto_jobs
  end
end
