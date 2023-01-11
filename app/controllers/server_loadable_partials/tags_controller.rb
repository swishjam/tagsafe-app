module ServerLoadablePartials
  class TagsController < BaseController
    def index
      if params[:q]
        tag_snippets = current_container.tag_snippets 
                                          .includes(tags: [:tag_identifying_data, :primary_audit]).joins('tags.tag_identifying_data')
                                          .where('tag_identifying_data.name LIKE ? OR tags.full_url LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
                                          .order('tags.last_released_at DESC')
                                          .page(params[:page] || 1).per(params[:per_page] || 8)
      else
        tag_snippets = current_container.tag_snippets 
                                          .includes(tags: [:tag_identifying_data, :primary_audit])
                                          .order('tags.last_released_at DESC')
                                          .page(params[:page] || 1).per(params[:per_page] || 8)
      end
      render turbo_stream: turbo_stream.replace(
        !params[:q].nil? ? "#{current_container.uid}_container_tags_table" : "#{current_container.uid}_container_tags_container",
        partial: !params[:q].nil? ? 'server_loadable_partials/tags/tag_table' : 'server_loadable_partials/tags/index',
        locals: { 
          tag_snippets: tag_snippets,
          container: current_container, 
          search_query: params[:q],
          allow_empty_table: !params[:q].nil?
        }
      )
    end
  end
end