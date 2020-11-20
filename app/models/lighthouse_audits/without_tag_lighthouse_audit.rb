class WithoutTagLighthouseAudit < LighthouseAudit
  has_one_attached :report_html

  after_destroy :purge_report_html

  def report_file_url(only_path = true)
    # figure out how to define host! we have env['host], does that work?
    rails_blob_path(report_html.attachment, only_path: only_path)
  end

  def purge_report_html
  report_html.purge
  end
end