module ServerLoadablePartials
  class TagsController < BaseController
    def index
      tags = current_domain.tags.joins(:tag_preferences)
                                  .order('tag_preferences.should_run_audit DESC')
                                  .order('removed_from_site_at ASC')
                                  .order('content_changed_at DESC')
                                  .page(params[:page] || 1).per(params[:per_page] || 9)
      most_recent_scan = current_domain.domain_scans&.most_recent
      render turbo_stream: turbo_stream.replace(
        "#{current_domain.id}_domain_tags",
        partial: 'server_loadable_partials/tags/index',
        locals: { tags: tags, domain: current_domain, most_recent_scan: most_recent_scan }
      )
    end
  end
end