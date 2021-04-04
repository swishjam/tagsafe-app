module Admin
  class TagImageDomainLookupPatternsController < BaseController
    def create
      TagImageDomainLookupPattern.create(permitted_params)
      display_toast_message("Successfully added url pattern.")
      redirect_to request.referrer
    end

    def destroy
      pattern = TagImageDomainLookupPattern.find(params[:id])
      pattern.destroy
      display_toast_message("Successfully deleted #{pattern.url_pattern} URL pattern.")
      redirect_to request.referrer
    end

    private
    def permitted_params
      params.require(:tag_image_domain_lookup_pattern).permit(:url_pattern, :tag_image_id)
    end
  end
end