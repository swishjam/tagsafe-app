class AlertConfigurationTagsController < LoggedInController
  before_action :find_alert_configuration

  def index
    @selected_tags = @alert_configuration.tags.includes(:tag_identifying_data)
    @unselected_tags = current_container.tags.includes(:tag_identifying_data)
                                            .order('tag_identifying_data.name', 'tags.url_hostname')
                                            .where.not(id: @selected_tags.collect(&:id))
  end

  def update
    tags = current_container.tags.where(uid: params[:tag_uids] || [])
    tag_attributes = tags.collect{ |tag| { tag_id: tag.id } }
    if @alert_configuration.update(alert_configuration_tags_attributes: tag_attributes)
      redirect_to alert_configuration_container_users_path(@alert_configuration)
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def find_alert_configuration
    @alert_configuration = current_container.alert_configurations.find_by(uid: params[:uid])
  end
end