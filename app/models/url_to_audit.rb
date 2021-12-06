class UrlToAudit < ApplicationRecord
  self.table_name = :urls_to_audit
  
  belongs_to :tag
  belongs_to :page_url
  has_many :audits, foreign_key: :audited_url_id, dependent: :destroy

  def generate_tagsafe_hosted_site_now!
    raise TagSafeHostedSiteError::AlreadyHosted, "Cannot generate TagSafe hosted site from a UrlToAudit with `tagsafe_hosted` = true" if tagsafe_hosted
    tagsafe_hosted_url = TagSafeHostedSiteGenerator.new(audit_url).generate_tagsafe_hosted_site
    tag.urls_to_audit.create(audit_url: tagsafe_hosted_url, display_url: audit_url, tagsafe_hosted: true, primary: true)
  end

  def formatted_display_url
    tagsafe_hosted ? "TagSafe-hosted version of #{display_url}" : display_url
  end
end