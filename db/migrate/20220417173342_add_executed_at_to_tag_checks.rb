class AddExecutedAtToTagChecks < ActiveRecord::Migration[6.1]
  def up
    add_column :tag_checks, :executed_at, :datetime
  end
end
