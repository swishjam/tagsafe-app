class CreateSlackSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :slack_settings do |t|
      t.integer :organization_id
      t.string :access_token
      t.string :app_id
      t.string :team_id
      t.string :team_name
    end
  end
end
