class AddIsMostCurrentFlagToAudits < ActiveRecord::Migration[6.1]
  def up
    add_reference :tags, :most_current_audit
  end

  def down
    remove_reference :tags, :most_current_audit
  end
end
