class LighthouseAuditsController < LoggedInController
  def show
    render html: LighthouseAudit.find(params[:id]).report_html.download.html_safe
  end
end