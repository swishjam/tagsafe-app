class ContainersController < LoggedInController
  skip_before_action :find_and_validate_container, only: [:new, :create, :index, :show]
  
  def create
    @container = Container.new(container_params)
    if @container.save
      current_user.containers << @container
      Role.USER_ADMIN.apply_to_container_user(current_user.container_user_for(@container))
      redirect_to container_tag_snippets_path(@container)
    else
      display_inline_errors(@container.errors.full_messages)
      @hide_navigation = true
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @container.update(container_params)
    render turbo_stream: turbo_stream.replace(
      'container_settings',
      partial: 'containers/edit_form',
      locals: { container: @container, success_message: 'Container settings updated.' }
    )
  end

  def show
    @container = current_user.containers.find_by!(uid: params[:uid])
    redirect_to container_tag_snippets_path(@container)
  rescue ActiveRecord::RecordNotFound => e
    redirect_to containers_path
  end
  
  private

  def container_params
    params.require(:container).permit(:name, :tagsafe_js_enabled, :defer_script_tags_by_default)
  end
end