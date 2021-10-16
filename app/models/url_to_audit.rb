class UrlToAudit < ApplicationRecord
  self.table_name = :urls_to_audit
  
  belongs_to :tag
  has_many :audits, foreign_key: :audited_url_id, dependent: :destroy
end