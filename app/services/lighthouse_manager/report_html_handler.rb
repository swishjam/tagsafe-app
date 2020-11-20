class LighthouseManager::ReportHtmlHandler
  def initialize(geppetto_url, file_name)
    @geppetto_url = geppetto_url
    @file_name = file_name
  end

  def write_report_to_local_file
    resp = get_content
    write_file(resp.body)
    written_file_location
  end

  def get_content
    HTTParty.get(@geppetto_url)
  end

  def write_file(content)
    unless @js_file
      @js_file = File.open(written_file_location, "w") 
      @js_file.puts content.force_encoding('UTF-8')
      @js_file.close
    end
    @js_file
  end

  def written_file_location
    "#{Util.create_dir_if_neccessary(Rails.root, 
                                      'public',
                                      'lighthouse_reports',
                                      Time.now.month.to_s, 
                                      Time.now.day.to_s)}/#{@file_name}.html"
  end
end