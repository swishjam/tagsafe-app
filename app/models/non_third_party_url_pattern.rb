class NonThirdPartyUrlPattern < ApplicationRecord
  belongs_to :container
  after_create :disable_pre_existing_url_patterns

  private

  def disable_pre_existing_url_patterns
    Tag.joins(tag: :container)
                    .where('containers.id = ? AND tags.full_url like ?', container_id, "%#{pattern}%")
                    .update_all(enabled: false, is_third_party_tag: false)
  end
end