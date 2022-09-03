class TagBuilderController < LoggedInController
  before_action :find_tag_being_built, except: :new

  def new
    tag = current_domain.tags.create!(is_draft: true, script_inject_is_disabled: false)
    redirect_to tag_builder_resource_path(tag)
  end

  def update
    if @tag.update(tag_params)
      redirect_to next_path
    else
      render params[:current_view].to_sym, status: :unprocessable_entity
    end
  end

  def resource; end

  def load_rules
    redirect_to tag_builder_resource_path if @tag.full_url.nil?
  end

  def performance
    redirect_to tag_builder_load_rules_path if @tag.script_inject_location.nil?
  end

  def position
    redirect_to tag_builder_load_rules_path if @tag.is_tagsafe_hosted.nil?
  end

  def review
  end

  private

  def find_tag_being_built
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
    redirect_to builder_new_tags_path if @tag.nil?
  end

  def tag_params
    params.require(:tag).permit(
      :js_script, 
      :full_url, 
      :script_inject_priority, 
      :script_inject_location, 
      :script_inject_event,
      :script_inject_is_disabled, 
      :execute_script_in_web_worker, 
      :is_tagsafe_hosted,
      :load_type,
      :is_draft
    )
  end

  def next_path
    {
      'resource' => tag_builder_load_rules_path(@tag),
      'load_rules' => tag_builder_performance_path(@tag),
      'performance' => tag_builder_review_path(@tag),
      'review' => tag_path(@tag)
    }[params[:current_view]]
  end
end