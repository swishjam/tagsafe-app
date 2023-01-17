class TagSnippetsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'Tags' }
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings' },
    )
  end

  def list
    render turbo_stream: turbo_stream.replace(
      "#{@container.uid}_tag_snippets_list",
      partial: 'tag_snippets/list',
      locals: { 
        container: @container,
        tag_snippets: @container.tag_snippets.includes(tags: [tag_identifying_data: :image_attachment]),
      }
    )
  end

  def new
    @tag_snippet = TagSnippet.new
    render_breadcrumbs(
      { url: containers_path, text: @container.name },
      { text: 'New Tag' }
    )
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings' },
    )
  end

  def create
    params[:tag_snippet][:state] = 'draft'
    params[:tag_snippet][:find_tags_injected_by_snippet_job_enqueued_at] = Time.current

    tag_snippet = @container.tag_snippets.new(tag_snippet_params)
    
    html = Nokogiri::HTML.fragment(params[:tag_snippet][:content])
    num_script_tags = html.css('script').count
    if num_script_tags != 1
      render turbo_stream: turbo_stream.replace(
        "new_tag_snippet_form",
        partial: 'tag_snippets/form',
        locals: {
          tag_snippet: tag_snippet,
          container: @container,
          error_messages: [num_script_tags.zero? ? 'Tag snippet must contain a script tag.' : 'Tag snippet must only contain a single script tag.'],
        }
      )
    else
      if tag_snippet.save
        # filename = "#{tag_snippet.uid}-#{Time.now.to_i}-#{rand()}.html"
        # Util.create_dir_if_neccessary(Rails.root, 'tmp', 'tag_snippets')
        # file = File.open(Rails.root.join('tmp', 'tag_snippets', filename), 'w')
        # file.puts(params[:tag_snippet][:content].force_encoding('UTF-8'))
        # file.close
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
    render_navigation_items(
      { url: container_tag_snippets_path(@container), text: 'Tags', active: true },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path(@container), text: 'Page Performance' },
      { url: container_settings_path(@container), text: 'Settings' },
    )
  end

  private

  def tag_snippet_params
    params.require(:tag_snippet).permit(:name, :state, :find_tags_injected_by_snippet_job_enqueued_at)
  end
end
