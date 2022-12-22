class NonThirdPartyUrlPatternsController < LoggedInController
  def create
    params[:non_third_party_url_pattern][:container_id] = params[:container_id]
    pattern = NonThirdPartyUrlPattern.new(non_third_party_url_pattern_params)
    if pattern.save
      current_user.broadcast_notification(message: 'Added new non-third party tag URL pattern.')
    else
      current_user.broadcast_notification(message: pattern.errors.full_messages)
    end
    render turbo_stream: turbo_stream.replace(
      "#{current_container.id}_non_third_party_url_patterns",
      partial: 'non_third_party_url_patterns/index',
      locals: { container: current_container }
    )
  end

  def destroy
    pattern = NonThirdPartyUrlPattern.find_by(uid: params[:uid])
    if pattern.destroy
      current_user.broadcast_notification(message: "Removed #{pattern.pattern} from the non-third party tag URL patterns list.")
    else
      current_user.broadcast_notification(message: pattern.errors.full_messages)
    end
    render turbo_stream: turbo_stream.remove(pattern)
  end

  private 

  def non_third_party_url_pattern_params
    params.require(:non_third_party_url_pattern).permit(:pattern, :container_id)
  end
end