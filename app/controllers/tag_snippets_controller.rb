class TagSnippetsController < LoggedInController
  def new
    @tag_snippet = TagSnippet.new
    render_breadcrumbs(
      { url: tags_path, text: 'All Tags' },
      { text: 'New Tag' }
    )
  end

  def create
    # <script>
    #   (function() {
    #       var s = document.createElement('script');
    #       s.setAttribute('src', 'https://www.thirdpartytag.com/script.js');
    #       document.head.appendChild(s);
    #   })()
    # </script>
    @tag_snippet = current_container.tag_snippets.new
    if @tag_snippet.save
      @tag_snippet.content.attach({
        io: StringIO.new(params[:tag_snippet][:content]),
        filename: "#{Time.now.to_i}-#{rand()}.js",
        content_type: 'text/javascript'
      })
      @tag_snippet.find_and_create_associated_tags_added_to_page_by_snippet
      redirect_to tag_snippet_path(@tag_snippet)
    else
      render :new, :unprocessable_entity
    end
  end

  def show
    @tag_snippet = current_container.tag_snippets.find_by!(uid: params[:uid])
        render_breadcrumbs(
      { url: tags_path, text: 'All Tags' },
      { text: "#{@tag_snippet.try_friendly_name} details" }
    )
  end

  private

  def tag_snippet_params
    params.require(:tag_snippet).permit()
  end
end