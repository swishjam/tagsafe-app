class CreateOtherTagsToInjectDuringAudit < ActiveRecord::Migration[6.1]
  def change
    create_table :additional_tags_to_inject_during_audit do |t|
      t.string :uid, index: true
      t.references :tag
      t.references :tag_to_inject, index: { name: :index_attida_on_tag_to_inject_id }
      t.timestamps
    end
  end
end
