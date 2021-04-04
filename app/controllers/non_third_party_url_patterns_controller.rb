class NonThirdPartyUrlPatternsController < LoggedInController
  def create
    params[:non_third_party_url_pattern][:domain_id] = params[:domain_id]
    pattern = NonThirdPartyUrlPattern.new(non_third_party_url_pattern_params)
    if pattern.save
      display_toast_message('Added new ignored tag URL pattern.')
    else
      display_toast_errors(pattern.errors.full_messages)
    end
    redirect_to settings_tag_settings_path
  end

  def destroy
    pattern = NonThirdPartyUrlPattern.find(params[:id])
    pattern.destroy
    display_toast_message('Removed ignored tag URL pattern.')
    redirect_to settings_tag_settings_path
  end

  private 

  def non_third_party_url_pattern_params
    params.require(:non_third_party_url_pattern).permit(:pattern, :domain_id)
  end
end