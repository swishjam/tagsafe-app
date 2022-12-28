class AddShouldAuditFlagToPageUrls < ActiveRecord::Migration[6.1]
  def change
    add_column :page_urls_tag_found_on, :should_audit, :boolean
    add_reference :user_invites, :redeemed_by_user
  end
end
