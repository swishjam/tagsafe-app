class TagSnippetsController < LoggedInController
  def list
    render turbo_stream: turbo_stream.replace(
      "#{current_container.uid}_tag_snippets_list",
      partial: 'tag_snippets/list',
      locals: { 
        container: current_container,
        tag_snippets: current_container.tag_snippets.includes(tags: [tag_identifying_data: :image_attachment]),
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
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end

  def create
    params[:tag_snippet][:state] = 'draft'
    @tag_snippet = current_container.tag_snippets.new(tag_snippet_params)
    if @tag_snippet.save
      filename = "#{@tag_snippet.uid}-#{Time.now.to_i}-#{rand()}.html"
      file = File.open(Rails.root.join('tmp', filename), 'w')
      file.puts params[:tag_snippet][:content].force_encoding('UTF-8')
      file.close

      @tag_snippet.content.attach({
        io: File.open(file),
        filename: filename,
        content_type: 'text/html'
      })

      File.delete(Rails.root.join('tmp', filename))
      redirect_to tag_snippet_path(@tag_snippet)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @tag_snippet = current_container.tag_snippets.find_by!(uid: params[:uid])
    @tag_snippet.update!(tag_snippet_params)
    redirect_to tag_snippet_path(@tag_snippet)
  end

  def show
    @tag_snippet = current_container.tag_snippets.find_by!(uid: params[:uid])
    render_breadcrumbs(
      { url: root_path, text: 'Tags' },
      { text: "#{@tag_snippet.name} Details" }
    )
    render_navigation_items(
      { url: root_path, text: 'Tags', active: true },
      { url: pull_requests_path, text: 'Pull Requests' },
      { url: all_releases_path, text: 'Releases' },
      { url: page_performance_path, text: 'Page Performance' },
      { url: settings_path, text: 'Settings' },
    )
  end

  private

  def tag_snippet_params
    params.require(:tag_snippet).permit(:name, :state)
  end
end
