class AddChangeRequestApprovalColumnsToTagVersions < ActiveRecord::Migration[6.1]
  def change
    # add_column :tag_versions, :change_request_decisioned_at, :timestamp
    # add_column :tag_versions, :container_user_id_change_request_decisioned_by, :bigint
    # add_index :tag_versions, :container_user_id_change_request_decisioned_by, name: :cu_id_change_request_decisioned_by
    # add_column :tag_versions, :change_request_decision, :string
    add_reference :tag_versions, :live_tag_version_at_time_of_decision
  end
end
