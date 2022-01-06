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

  def resource_type_icon_html
    {
      'img' => "<img src='#{name}' style='position: relative'>".html_safe,
      'css' => HtmlHelper.CODE_FILE_ICON(color: 'purple'),
      'link' => HtmlHelper.CODE_FILE_ICON(color: 'purple'),
      'script' => HtmlHelper.CODE_FILE_ICON(color: 'orange'),
      'xmlhttprequest' => HtmlHelper.HTTP_REQUEST_ICON(color: 'blue'),
      'fetch' => HtmlHelper.HTTP_REQUEST_ICON(color: 'grey'),
      'navigation' => HtmlHelper.DOCUMENT_FILE_ICON(color: 'blue')
    }[initiator_type]
  end
end