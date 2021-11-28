module ServerLoadablePartials
  class TagVersionsController < BaseController
    def index
      tag = Tag.find(params[:tag_id])
      tag_versions = tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
      render turbo_stream: turbo_stream.replace(
        "#{tag.uid}_tag_tag_versions_container",
        partial: 'server_loadable_partials/tag_versions/index',
        locals: { tag_versions: tag_versions, tag: tag }
      )
    end

    def diff
      if params[:diff_type] == 'split'
        render_split_diff
      else
        render_unified_diff
      end
    end

    private

    def render_unified_diff
      tag_version = TagVersion.includes(:tag).find(params[:id])
      permitted_to_view?(tag_version)
      previous_tag_version = tag_version.previous_version
  
      diff = Diffy::Diff.new(
        previous_tag_version&.content&.force_encoding('UTF-8'), 
        tag_version.content.force_encoding('UTF-8'), 
        format: :html, 
        include_plus_and_minus_in_html: true,
        include_diff_info: true
      ).to_s(:html)
      
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.id}_diff",
        partial: 'server_loadable_partials/tag_versions/unified_diff',
        locals: { tag: tag_version.tag, tag_version: tag_version, diff: diff.html_safe }
      )
    end

    def render_split_diff
      tag_version = TagVersion.includes(:tag).find(params[:id])
      permitted_to_view?(tag_version)
      previous_tag_version = tag_version.previous_version
  
      diff = Diffy::SplitDiff.new(
        previous_tag_version&.content&.force_encoding('UTF-8'), 
        tag_version.content.force_encoding('UTF-8'), 
        format: :html, 
        include_plus_and_minus_in_html: true,
        include_diff_info: true
      )
      
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.id}_diff",
        partial: 'server_loadable_partials/tag_versions/split_diff',
        locals: { tag: tag_version.tag, tag_version: tag_version, additions: diff.right.html_safe, deletions: diff.left.html_safe }
      )
    end
  end
end