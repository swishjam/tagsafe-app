class TagSnippetsController < LoggedInController
  def index
    render_breadcrumbs(
      { url: root_path, text: @container.name },
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
      { url: root_path, text: 'All Tags' },
      { text: 'New Tag' }
    )
    render_navigation_items(
      { url: root_path, text: 'Tags' },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings' },
    )
  end

  def create
    params[:tag_snippet][:state] = 'draft'
    params[:tag_snippet][:find_tags_injected_by_snippet_job_enqueued_at] = Time.current
    @tag_snippet = @container.tag_snippets.new(tag_snippet_params)
    if @tag_snippet.save
      filename = "#{@tag_snippet.uid}-#{Time.now.to_i}-#{rand()}.html"
      Util.create_dir_if_neccessary(Rails.root, 'tmp', 'tag_snippets')
      file = File.open(Rails.root.join('tmp', 'tag_snippets', filename), 'w')
      file.puts(params[:tag_snippet][:content].force_encoding('UTF-8'))
      file.close

      FindAndCreateTagsForTagSnippetJob.perform_later(@tag_snippet, filename)

      redirect_to tag_snippet_path(@tag_snippet)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @tag_snippet = @container.tag_snippets.find_by!(uid: params[:uid])
    @tag_snippet.update!(tag_snippet_params)
    redirect_to tag_snippet_path(@tag_snippet)
  end

  def show
    @tag_snippet = @container.tag_snippets.find_by!(uid: params[:uid])
    render_breadcrumbs(
      { url: root_path, text: 'Tags' },
      { text: "#{@tag_snippet.name} Details" }
    )
    render_navigation_items(
      { url: root_path, text: 'Tags', active: true },
      { url: container_change_requests_path(@container), text: 'Change Requests' },
      { url: container_page_performance_path, text: 'Page Performance' },
      { url: container_settings_path, text: 'Settings' },
    )
  end

  private

  def tag_snippet_params
    params.require(:tag_snippet).permit(:name, :state, :find_tags_injected_by_snippet_job_enqueued_at)
  end
end
