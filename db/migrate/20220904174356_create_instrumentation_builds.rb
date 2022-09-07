class CreateInstrumentationBuilds < ActiveRecord::Migration[6.1]
  def change
    create_table :instrumentation_builds do |t|
      t.string :uid, index: true
      t.references :domain
      t.mediumtext :description

      t.datetime :created_at, null: false
    end
  end
end
