module ServerLoadablePartials
  class TagVersionsController < BaseController
    def index
      tag = current_domain.tags.find(params[:tag_id])
      tag_versions = tag.tag_versions.page(params[:page] || 1).per(params[:per_page] || 10)
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_tag_versions_table",
        partial: 'server_loadable_partials/tag_versions/table',
        locals: { tag_versions: tag_versions, tag: tag }
      )
    end

    def diff
      tag = current_domain.tags.find(params[:tag_id])
      tag_version = tag.tag_versions.includes(:tag).find(params[:id])
      previous_tag_version = tag_version.previous_version
      diff_analyzer = DiffAnalyzer.new(
        new_content: tag_version.content, 
        previous_content: previous_tag_version&.content,
        num_lines_of_context: params[:num_lines_of_context] || 7,
        include_diff_info: true
      )
      if params[:diff_type] == 'split'
        render_split_diff(tag, tag_version, diff_analyzer)
      else
        render_unified_diff(tag, tag_version, diff_analyzer)
      end
    end

    private

    def render_unified_diff(tag, tag_version, diff_analyzer)
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_diff",
        partial: 'server_loadable_partials/tag_versions/unified_diff',
        locals: { 
          tag: tag, 
          tag_version: tag_version, 
          diff_html: diff_analyzer.html_unified_diff,
          num_additions: diff_analyzer.num_additions,
          num_deletions: diff_analyzer.num_deletions,
          total_changes: diff_analyzer.total_changes
        }
      )
    end

    def render_split_diff(tag, tag_version, diff_analyzer)
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_diff",
        partial: 'server_loadable_partials/tag_versions/split_diff',
        locals: { 
          tag: tag, 
          tag_version: tag_version, 
          additions_html: diff_analyzer.html_split_diff_additions, 
          deletions_html: diff_analyzer.html_split_diff_deletions,
          num_additions: diff_analyzer.num_additions,
          num_deletions: diff_analyzer.num_deletions,
          total_changes: diff_analyzer.total_changes
        }
      )
    end
  end
end