class AlertConfigurationTagsController < LoggedInController
  before_action :find_alert_configuration

  def index
    @selected_tags = @alert_configuration.tags.includes(:tag_identifying_data)
    @unselected_tags = current_domain.tags.includes(:tag_identifying_data)
                                            .order('tag_identifying_data.name', 'tags.url_domain')
                                            .where.not(id: @selected_tags.collect(&:id))
  end

  def update
    tags = current_domain.tags.where(uid: params[:tag_uids] || [])
    tag_attributes = tags.collect{ |tag| { tag_id: tag.id } }
    if @alert_configuration.update(alert_configuration_tags_attributes: tag_attributes)
      redirect_to alert_configuration_domain_users_path(@alert_configuration)
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def find_alert_configuration
    @alert_configuration = current_domain.alert_configurations.find_by(uid: params[:uid])
  end
end