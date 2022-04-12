module ServerLoadablePartials
  class TagVersionsController < BaseController
    def index
      tag = current_domain.tags.find_by(uid: params[:tag_uid])
      tag_versions = tag.tag_versions.most_recent_first.page(params[:page] || 1).per(params[:per_page] || 10)
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_tag_versions_table",
        partial: 'server_loadable_partials/tag_versions/table',
        locals: { tag_versions: tag_versions, tag: tag }
      )
    end

    def diff
      tag = current_domain.tags.find_by(uid: params[:tag_uid])
      tag_version = tag.tag_versions.find_by(uid: params[:uid])
      previous_tag_version = tag_version.previous_version
      diff_analyzer = DiffAnalyzer.new(
        new_content: tag_version.content(formatted: true),
        previous_content: previous_tag_version&.content(formatted: true),
        num_lines_of_context: params[:num_lines_of_context] || 7,
        include_diff_info: true
      )
      if params[:diff_type] == 'split'
        render_split_diff(tag, tag_version, diff_analyzer)
      else
        render_unified_diff(tag, tag_version, diff_analyzer)
      end
    end

    def live_comparison
      tag = current_domain.tags.find_by(uid: params[:tag_uid])
      tag_version = tag.tag_versions.find_by(uid: params[:uid])
      live_content = TagManager::ContentFetcher.new(tag).fetch!
      formatted_content = TagManager::JsBeautifier.beautify_string!(live_content)
      diff_analyzer = DiffAnalyzer.new(
        new_content: formatted_content,
        previous_content: tag_version.content(formatted: true),
        num_lines_of_context: params[:num_lines_of_context] || 7,
        include_diff_info: true
      )
      render_split_diff(tag, tag_version, diff_analyzer)
    end

    private

    def render_unified_diff(tag, tag_version, diff_analyzer)
      locals = Rails.cache.fetch("#{tag_version.uid}-unified-git-diff") do
        {
          tag: tag,
          tag_version: tag_version,
          diff_html: diff_analyzer.html_unified_diff&.html_safe,
          num_additions: diff_analyzer.num_additions,
          num_deletions: diff_analyzer.num_deletions,
          total_changes: diff_analyzer.total_changes
        }
      end
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_diff",
        partial: 'server_loadable_partials/tag_versions/unified_diff',
        locals: locals
      )
    end

    def render_split_diff(tag, tag_version, diff_analyzer)
      locals = Rails.cache.fetch("#{tag_version.uid}-split-git-diff") do 
        { 
          tag: tag, 
          tag_version: tag_version, 
          additions_html: diff_analyzer.html_split_diff_additions&.html_safe, 
          deletions_html: diff_analyzer.html_split_diff_deletions&.html_safe,
          num_additions: diff_analyzer.num_additions,
          num_deletions: diff_analyzer.num_deletions,
          total_changes: diff_analyzer.total_changes
        }
      end
      render turbo_stream: turbo_stream.replace(
        "#{tag_version.uid}_diff",
        partial: 'server_loadable_partials/tag_versions/split_diff',
        locals: locals
      )
    end
  end
end