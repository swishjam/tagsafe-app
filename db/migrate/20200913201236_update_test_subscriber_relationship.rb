class UpdateTestSubscriberRelationship < ActiveRecord::Migration[5.2]
  def change
    remove_column :test_subscribers, :script_id
    remove_column :test_subscribers, :domain_id
    add_column :test_subscribers, :script_subscriber_id, :integer
  end
end
