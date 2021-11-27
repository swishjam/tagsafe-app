class PageLoadResource < ApplicationRecord
  belongs_to :performance_audit

  # scope :display_for_waterfall, -> { where.not(entry_type: %w[navigation paint measure mark]) }
  scope :display_for_waterfall, -> { where.not(entry_type: %w[paint measure mark]) }

  def name_without_query_string
    parsed_url = URI.parse(name)
    "#{parsed_url.scheme}://#{parsed_url.hostname}#{parsed_url.path}"
  end

  def audit
    @audit ||= performance_audit.audit
  end
end