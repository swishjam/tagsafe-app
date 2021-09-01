class NonThirdPartyUrlPatternsController < LoggedInController
  def create
    params[:non_third_party_url_pattern][:domain_id] = params[:domain_id]
    pattern = NonThirdPartyUrlPattern.new(non_third_party_url_pattern_params)
    if pattern.save
      current_user.broadcast_notification('Added new non-third party tag URL pattern.')
    else
      current_user.broadcast_notification(pattern.errors.full_messages)
    end
    render turbo_stream: turbo_stream.replace(
      "#{current_domain.id}_non_third_party_url_patterns",
      partial: 'non_third_party_url_patterns/index',
      locals: { domain: current_domain }
    )
  end

  def destroy
    pattern = NonThirdPartyUrlPattern.find(params[:id])
    if pattern.destroy
      current_user.broadcast_notification("Removed #{pattern.pattern} from the non-third party tag URL patterns list.")
    else
      current_user.broadcast_notification(pattern.errors.full_messages)
    end
    render turbo_stream: turbo_stream.remove(pattern)
  end

  private 

  def non_third_party_url_pattern_params
    params.require(:non_third_party_url_pattern).permit(:pattern, :domain_id)
  end
end