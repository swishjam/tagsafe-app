class AddFalgs < ActiveRecord::Migration[6.1]
  def change
    create_table :flags do |t|
      t.string :uid
      t.string :name
      t.string :slug
      t.string :description
      t.string :default_value
      t.timestamps
    end

    create_table :object_flags do |t|
      t.string :uid
      t.references :object, polymorphic: true
      t.references :flag
      t.string :value
      t.timestamps
    end
  end
end
