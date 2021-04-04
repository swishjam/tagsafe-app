class CreateTagVersionSubscriber < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_version_subscribers do |t|
      t.references :user
      t.references :tag
    end
  end
end
