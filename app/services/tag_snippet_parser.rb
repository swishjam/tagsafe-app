class TagSnippetParser
  def self.make_html_content_javascript_executable(html_content)
    dom = Nokogiri::HTML.fragment(html_content)
    script_tag = dom.css('script')[0]
    js = "(function(){var s = document.createElement('script'); "
    script_tag.attributes.each do |attr_name, attr_value|
      js += "s.setAttribute('#{attr_name}', '#{attr_value}'); "
    end
    js += "s.innerText = \'#{script_tag.text.gsub("\"", "\\'")}\';"
    js += '})();'
  end
end