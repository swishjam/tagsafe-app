class AddCreatedByContainerUserToContainers < ActiveRecord::Migration[6.1]
  def change
    add_reference :containers, :created_by_user
  end
end
