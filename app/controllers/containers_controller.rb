class ContainersController < LoggedInController
  skip_before_action :ensure_container, only: [:new, :create]

  def install_script
    stream_modal(locals: { instrumentation_key: current_container.instrumentation_key })
  end

  def new
    @container = Container.new
  end
  
  def create
    @container = Container.new(container_params)
    if @container.save
      set_current_container(@container)
      if current_user.nil?
        redirect_to new_registration_path
      else
        current_user.containers << @container
        Role.USER_ADMIN.apply_to_container_user(current_user.container_user_for(@container))
        redirect_to tags_path
      end
    else
      display_inline_errors(@container.errors.full_messages)
      @hide_navigation = true
      render :new, status: :unprocessable_entity
    end
  end

  def update_current_container
    # container = Container.find_by!(uid: params[:uid])
    container = current_user.containers.find_by!(uid: params[:uid])
    set_current_container(container)
    redirect_to request.referrer
  end
  
  private

  def container_params
    params.require(:container).permit(:name)
  end
end