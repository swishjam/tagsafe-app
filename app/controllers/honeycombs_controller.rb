class HoneycombsController < LoggedInController
  def chart
    tags = current_domain.tags.is_third_party_tag.includes(:tag_identifying_data, :tag_preferences, most_current_audit: :average_delta_performance_audit)
    audits = current_domain.audits
    render turbo_stream: turbo_stream.replace(
      "domain_#{current_domain.uid}_honeycomb_chart",
      partial: 'honeycombs/chart',
      locals: { tags: tags }
    )
  end

  def show
    tag = current_domain.tags.find_by(uid: params[:uid])
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_honeycomb_details",
      partial: 'honeycombs/show',
      locals: { 
        tag: tag,
        audit: tag.most_current_audit
      }
    )
  end
end