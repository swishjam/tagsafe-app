class TagManagementController < LoggedInController
  def index
    @tags = Tag.all
  end

  def create
    current_domain.tags.new(tag_params)
  end

  private

  def tag_params
    params.require(:tag).permit(:full_url, :load_type, :is_tagsafe_hosted)
  end
end