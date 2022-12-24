module ServerLoadablePartials
  class TagsController < BaseController
    def index
      if params[:q]
        tags = current_container.tags.includes(:tag_identifying_data, :primary_audit).joins(:tag_identifying_data)
                                    .where('tag_identifying_data.name LIKE ? OR tags.full_url LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
                                    .order(last_released_at: :DESC)
                                    .page(params[:page] || 1).per(params[:per_page] || 12)
      else
        tags = current_container.tags.includes(:tag_identifying_data, :primary_audit)
                                    .order(last_released_at: :DESC)
                                    .page(params[:page] || 1).per(params[:per_page] || 12)
      end
      render turbo_stream: turbo_stream.replace(
        !params[:q].nil? ? "#{current_container.uid}_container_tags_table" : "#{current_container.uid}_container_tags_container",
        partial: !params[:q].nil? ? 'server_loadable_partials/tags/tag_table' : 'server_loadable_partials/tags/index',
        locals: { 
          tags: tags,
          has_received_tagsafe_js_events: tags.any? || current_container.tagsafe_js_event_batches.any?,
          container: current_container, 
          search_query: params[:q],
          allow_empty_table: !params[:q].nil?
        }
      )
    end
  end
end