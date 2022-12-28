class PageUrlsTagFoundOnController < LoggedInController
  before_action :find_tag
  before_action :find_page_url_tag_found_on

  def update
    if @page_url_tag_found_on.update(page_url_tag_found_on_params)
    else
      render turbo_stream: turbo_stream.replace(
        "#{@tag.uid}_settings",
        partial: 'tags/form',
        locals: {
          tag: @tag,
          error_message: @page_url_tag_found_on.errors.full_messages.join('. ')
        }
      )
    end
  end

  private

  def page_url_tag_found_on_params
    params.require(:page_url_tag_found_on).permit(:should_audit)
  end

  def find_tag
    @tag = current_container.tags.find_by(uid: params[:tag_uid])
  end

  def find_page_url_tag_found_on
    @page_url_tag_found_on = @tag.page_urls_tag_found_on.find_by(uid: params[:uid])
  end
end