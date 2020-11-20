class LighthouseAuditsController < ApplicationController
  def show
    render html: LighthouseAudit.find(params[:id]).report_html.download.html_safe
  end

  # def make_primary
  #   @lighthouse_audit = LighthouseAudit.find(params[:id])
  #   permitted_to_view?(@lighthouse_audit, raise_error: true)
  #   @lighthouse_audit.make_primary!
  #   flash[:banner_message] = "Primary lighthouse audit updated."
  #   redirect_to request.referrer
  # end
end