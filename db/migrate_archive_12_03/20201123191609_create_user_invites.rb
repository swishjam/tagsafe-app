class CreateUserInvites < ActiveRecord::Migration[5.2]
  def change
    create_table :user_invites do |t|
      t.integer :organization_id
      t.integer :invited_by_user_id
      t.string :email
      t.string :token
      t.timestamp :expires_at
      t.timestamp :redeemed_at
      t.timestamp :created_at, default: "CURRENT_TIMESTAMP"
    end
  end
end
