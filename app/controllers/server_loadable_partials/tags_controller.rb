module ServerLoadablePartials
  class TagsController < BaseController
    def index
      if params[:q]
        tags = current_domain.tags.includes(:tag_identifying_data, most_current_audit: :average_delta_performance_audit).joins(:tag_identifying_data)
                                    .where('tag_identifying_data.name LIKE ? OR tags.full_url LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
                                    .order(last_released_at: :DESC)
                                    .page(params[:page] || 1).per(params[:per_page] || 9)
      else
        tags = current_domain.tags.includes(:tag_identifying_data, most_current_audit: :average_delta_performance_audit)
                                    .order(last_released_at: :DESC)
                                    .page(params[:page] || 1).per(params[:per_page] || 9)
      end
      render turbo_stream: turbo_stream.replace(
        !params[:q].nil? ? "#{current_domain.uid}_domain_tags_table" : "#{current_domain.uid}_domain_tags_container",
        partial: !params[:q].nil? ? 'server_loadable_partials/tags/tag_table' : 'server_loadable_partials/tags/index',
        locals: { 
          tags: tags, 
          domain: current_domain, 
          search_query: params[:q],
          allow_empty_table: !params[:q].nil?
        }
      )
    end
  end
end