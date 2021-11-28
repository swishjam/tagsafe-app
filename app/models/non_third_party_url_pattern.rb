class NonThirdPartyUrlPattern < ApplicationRecord
  
  belongs_to :domain

  after_create :disable_pre_existing_url_patterns

  private

  def disable_pre_existing_url_patterns
    TagPreference.joins(tag: :domain)
                    .where('domains.id = ? AND tags.full_url like ?', domain_id, "%#{pattern}%")
                    .update_all(enabled: false, is_third_party_tag: false)
  end
end