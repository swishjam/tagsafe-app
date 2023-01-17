class ContainersController < LoggedInController
  skip_before_action :find_and_validate_container, only: [:new, :create, :index]
  
  def create
    @container = Container.new(container_params)
    if @container.save
      set_current_container(@container)
      if current_user.nil?
        redirect_to new_registration_path
      else
        current_user.containers << @container
        Role.USER_ADMIN.apply_to_container_user(current_user.container_user_for(@container))
        redirect_to root_path
      end
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
  
  private

  def container_params
    params.require(:container).permit(:name, :tagsafe_js_enabled, :defer_script_tags_by_default)
  end
end