module ServerLoadablePartials
  class TagsController < BaseController
    def index
      tag_snippets = @container.tag_snippets 
                                        .includes(tags: [tag_identifying_data: :image_attachment])
                                        .page(params[:page] || 1).per(params[:per_page] || 8)
      render turbo_stream: turbo_stream.replace(
        "#{@container.uid}_container_tags_container",
        partial: 'server_loadable_partials/tags/index',
        locals: { 
          tag_snippets: tag_snippets,
          container: @container, 
        }
      )
    end
  end
end