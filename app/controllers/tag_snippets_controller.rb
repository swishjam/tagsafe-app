class TagSnippetsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Tags' }
    )
    render_default_navigation_items(:tags)
  end

  def list
    tag_snippets = @container.tag_snippets
                                .includes(tags: [tag_identifying_data: :image_attachment])
                                .not_deleted
                                .order(state: :DESC)
    render turbo_stream: turbo_stream.replace(
      "#{@container.uid}_tag_snippets_list",
      partial: 'tag_snippets/list',
      locals: { 
        container: @container,
        tag_snippets: tag_snippets,
      }
    )
  end

  def new
    @tag_snippet = TagSnippet.new
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'New Tag' }
    )
    render_default_navigation_items(:tags)
  end

  def create
    params[:tag_snippet][:state] = 'draft'
    params[:tag_snippet][:find_tags_injected_by_snippet_job_enqueued_at] = Time.current
    tag_snippet = @container.tag_snippets.new(tag_snippet_params)

    if params[:tag_snippet][:content].blank?
      render turbo_stream: turbo_stream.replace(
        "new_tag_snippet_form",
        partial: 'tag_snippets/form',
        locals: {
          tag_snippet: tag_snippet,
          container: @container,
          error_messages: ['Must provide tag content.']
        }
      )
    elsif tag_snippet.save
      FindAndCreateTagsForTagSnippetJob.perform_later(tag_snippet, params[:tag_snippet][:content])
      redirect_to container_tag_snippet_path(@container, tag_snippet)
    else
      render turbo_stream: turbo_stream.replace(
        "new_tag_snippet_form",
        partial: 'tag_snippets/form',
        locals: {
          tag_snippet: tag_snippet,
          container: @container,
          error_messages: tag_snippet.errors.full_messages
        }
      )
    end
  end

  def update
    @tag_snippet = @container.tag_snippets.find_by!(uid: params[:uid])
    @tag_snippet.update!(tag_snippet_params)
    redirect_to container_tag_snippet_path(@container, @tag_snippet)
  end

  def show
    @tag_snippet = @container.tag_snippets.find_by!(uid: params[:uid])
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { text: "#{@tag_snippet.name} Details" }
    )
    render_default_navigation_items(:tags)
  end

  private

  def tag_snippet_params
    params.require(:tag_snippet).permit(:name, :state, :find_tags_injected_by_snippet_job_enqueued_at)
  end
end
