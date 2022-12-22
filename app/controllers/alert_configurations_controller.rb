class AlertConfigurationsController < LoggedInController
  def index
    @alert_configurations = current_container.alert_configurations.most_recent_first.page(params[:page] || 1).per(10)
    render_breadcrumbs(text: 'Alerts')
  end

  def show
    @alert_configuration = current_container.alert_configurations.find_by(uid: params[:uid])
    render_breadcrumbs(
      { url: alert_configurations_path, text: 'Alerts'},
      { text: "#{@alert_configuration.name}" }
    )
  end

  def new
    @alert_configuration = current_container.alert_configurations.new
    render_breadcrumbs(text: 'New Alert')
  end

  def trigger_rules
    @alert_configuration = current_container.alert_configurations.find_by(uid: params[:uid])
    render_breadcrumbs(text: 'New Alert')
  end

  def create
    alert_configuration_klass = params[:alert_configuration][:type].constantize
    tags = current_container.tags.where(uid: params[:tag_uids] || [])
    params[:alert_configuration][:container_id] = current_container.id
    params[:alert_configuration][:disabled] = true
    @alert_configuration = alert_configuration_klass.new(alert_configuration_params)
    if @alert_configuration.save
      redirect_to trigger_rules_alert_configuration_path(@alert_configuration)
    else
      redirect_to request.referrer
    end
  end

  def update
    @alert_configuration = current_container.alert_configurations.find_by(uid: params[:uid])
    params[:alert_configuration][:container_id] = current_container.id
    params[:alert_configuration][:enabled_for_all_tags] = params[:alert_configuration][:enabled_for_all_tags] == 'true'
    unless params[:alert_configuration][:trigger_rules].is_a?(String)
      params[:alert_configuration][:trigger_rules] = (params[:alert_configuration][:trigger_rules] || {}).to_json
    end

    params[:tag_uids] ||= []
    pre_existing_tag_uids = @alert_configuration.tags.collect(&:uid)
    added_tag_uids = params[:tag_uids].difference(pre_existing_tag_uids)
    removed_tag_uids = pre_existing_tag_uids.difference(params[:tag_uids])

    if added_tag_uids.any?
      added_tags = current_container.tags.where(uid: added_tag_uids)
      @alert_configuration.update!(alert_configuration_tags_attributes: added_tags.collect{ |tag| { tag_id: tag.id }})
    end

    if removed_tag_uids.any?
      @alert_configuration.alert_configuration_tags.joins(:tag).where(tag: { uid: removed_tag_uids }).destroy_all
    end

    params[:container_user_uids] ||= []
    pre_existing_container_user_uids = @alert_configuration.container_users.collect(&:uid)
    added_container_user_uids = params[:container_user_uids].difference(pre_existing_container_user_uids)
    removed_container_user_uids = pre_existing_container_user_uids.difference(params[:container_user_uids])

    if added_container_user_uids.any?
      added_container_users = current_container.container_users.where(uid: added_container_user_uids)
      @alert_configuration.update!(alert_configuration_container_users_attributes: added_container_users.collect{ |container_user| { container_user_id: container_user.id }})
    end

    if removed_container_user_uids.any?
      @alert_configuration.alert_configuration_container_users.joins(:container_user).where(container_user: { uid: removed_container_user_uids }).destroy_all
    end

    if @alert_configuration.update(alert_configuration_params)
      redirect_to next_path
    else
      redirect_to request.referrer
    end
  end

  private

  def alert_configuration_params
    params.require(:alert_configuration).permit(
      :container_id, 
      :type, 
      :name, 
      :trigger_rules, 
      :enabled_for_all_tags, 
      :disabled, 
      alert_configuration_container_users_attributes: [:container_user_id],
      alert_configuration_tags_attributes: [:tag_id]
    )
  end

  def next_path
    {
      'type' => trigger_rules_alert_configuration_path(@alert_configuration),
      'trigger_rules' => alert_configuration_tags_path(@alert_configuration),
      'tags' => alert_configuration_container_users_path(@alert_configuration),
      'container_users' => alert_configuration_path(@alert_configuration, review: true),
      'review' => alert_configuration_path(@alert_configuration)
    }[params[:current_view]]
  end
end