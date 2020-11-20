class LighthouseAuditResultsController < ApplicationController
  def report
    render html: LighthouseAuditResult.find(params[:id]).report_html.download.html_safe
  end
end