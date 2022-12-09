class TagConfigurationsController < LoggedInController
  before_action :find_tag

  def new
    if @tag.draft_tag_configuration
      redirect_to edit_tag_tag_configuration_path(@tag, @tag.draft_tag_configuration)
    else
      @tag_configuration = DraftTagConfiguration.new(tag: @tag)
    end
  end

  def edit
    @tag_configuration = @tag.draft_tag_configuration
    redirect_to new_tag_tag_configuration_path(@tag) if @tag_configuration.nil?
  end

  def create
    params[:tag_configuration][:tag_id] = @tag.id
    params[:tag_configuration][:release_check_minute_interval] = 0 if ['false', nil].include?(params[:tag_configuration][:is_tagsafe_hosted])
    @tag_configuration = DraftTagConfiguration.new(tag_configuration_params)
    if @tag_configuration.save
      # redirect_to tag_path(@tag)
      redirect_to tags_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @tag_configuration = DraftTagConfiguration.find_by(uid: params[:uid])
    params[:tag_configuration][:tag_id] = @tag.id
    params[:tag_configuration][:release_check_minute_interval] = 0 if ['false', nil].include?(params[:tag_configuration][:is_tagsafe_hosted])
    if @tag_configuration.update(tag_configuration_params)
      redirect_to tag_path(@tag)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_tag
    @tag = current_domain.tags.find_by(uid: params[:tag_uid])
  end

  def tag_configuration_params
    params.require(:tag_configuration).permit(
      %i[
        tag_id
        release_check_minute_interval 
        scheduled_audit_minute_interval 
        load_type 
        is_tagsafe_hosted 
        script_inject_priority 
        script_inject_location 
        script_inject_event 
        execute_script_in_web_worker 
        enabled
      ]
    )
  end
end