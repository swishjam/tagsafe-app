module Admin
  class ScriptImageDomainLookupPatternsController < BaseController
    def create
      ScriptImageDomainLookupPattern.create(permitted_params)
      display_toast_message("Successfully added url pattern.")
      redirect_to request.referrer
    end

    def destroy
      pattern = ScriptImageDomainLookupPattern.find(params[:id])
      pattern.destroy
      display_toast_message("Successfully deleted #{pattern.url_pattern} URL pattern.")
      redirect_to request.referrer
    end

    private
    def permitted_params
      params.require(:script_image_domain_lookup_pattern).permit(:url_pattern, :script_image_id)
    end
  end
end