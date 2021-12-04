module ServerLoadablePartials
  class TagsController < BaseController
    def index
      tags = current_domain.tags.includes(:tag_preferences, :tag_image)
                                  .order('tag_preferences.enabled DESC, removed_from_site_at ASC, content_changed_at DESC')
                                  .page(params[:page] || 1).per(params[:per_page] || 9)
      render turbo_stream: turbo_stream.replace(
        "#{current_domain.uid}_domain_tags_container",
        partial: 'server_loadable_partials/tags/index',
        locals: { tags: tags, domain: current_domain }
      )
    end
  end
end