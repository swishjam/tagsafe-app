class AddMostRecentTagVersionToTag < ActiveRecord::Migration[6.1]
  def up
    add_reference :tags, :most_recent_tag_version
  end
end
