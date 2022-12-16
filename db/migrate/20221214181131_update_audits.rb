class UpdateAudits < ActiveRecord::Migration[6.1]
  def change
    rename_table :audits, :legacy_audits

    create_table :audits do |t|
      t.string :uid, index: true
      t.references :container
      t.references :tag
      t.references :tag_version
      t.references :page_url
      t.references :initiated_by_container_user
      t.float :tagsafe_score
      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamps
    end

    create_table :audit_components do |t|
      t.string :uid, index: true
      t.string :type
      t.references :audit
      t.float :score
      t.float :score_weight
      t.text :raw_results
      t.timestamp :lambda_response_received_at
      t.timestamp :started_at
      t.timestamp :completed_at
      t.timestamps
    end
  end
end
