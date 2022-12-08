class HoneycombsController < LoggedInController
  def index
    render_breadcrumbs(text: 'Tag Health')
  end

  def chart
    tags = current_domain.tags.includes(:tag_identifying_data, most_current_audit: :average_delta_performance_audit)
    honeycomb_rows = HoneycombChartFormatter.new(tags).format_rows!
    render turbo_stream: turbo_stream.replace(
      "domain_#{current_domain.uid}_honeycomb_chart",
      partial: 'honeycombs/chart',
      locals: {  honeycomb_rows: honeycomb_rows }
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