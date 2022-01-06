class BlockedResource < ApplicationRecord
  belongs_to :performance_audit
  validates_presence_of :url, :resource_type

  def resource_type_icon_html
    {
      'img' => "<img src='#{url}' style='width: 15px;'>".html_safe,
      'css' => HtmlHelper.CODE_FILE_ICON(color: 'purple'),
      'link' => HtmlHelper.CODE_FILE_ICON(color: 'purple'),
      'script' => HtmlHelper.CODE_FILE_ICON(color: 'orange'),
      'xmlhttprequest' => HtmlHelper.HTTP_REQUEST_ICON(color: 'blue'),
      'fetch' => HtmlHelper.HTTP_REQUEST_ICON(color: 'grey'),
      'navigation' => HtmlHelper.DOCUMENT_FILE_ICON(color: 'blue')
    }[resource_type]
  end
end