class AlertConfigurationsController < LoggedInController
  def index
    @alert_configurations = current_domain.alert_configurations.most_recent_first.page(params[:page] || 1).per(10)
    render_breadcrumbs(text: 'Alerts')
  end

  def show
    @alert_configuration = current_domain.alert_configurations.find_by(uid: params[:uid])
    render_breadcrumbs(
      { url: alert_configurations_path, text: 'Alerts'},
      { text: "#{@alert_configuration.name}" }
    )
  end

  def new
    @alert_configuration = current_domain.alert_configurations.new
    render_breadcrumbs(text: 'New Alert')
  end

  def trigger_rules
    @alert_configuration = current_domain.alert_configurations.find_by(uid: params[:uid])
    render_breadcrumbs(text: 'New Alert')
  end

  def create
    alert_configuration_klass = params[:alert_configuration][:type].constantize
    tags = current_domain.tags.where(uid: params[:tag_uids] || [])
    params[:alert_configuration][:domain_id] = current_domain.id
    params[:alert_configuration][:disabled] = true
    @alert_configuration = alert_configuration_klass.new(alert_configuration_params)
    if @alert_configuration.save
      redirect_to trigger_rules_alert_configuration_path(@alert_configuration)
    else
      redirect_to request.referrer
    end
  end

  def update
    @alert_configuration = current_domain.alert_configurations.find_by(uid: params[:uid])
    params[:alert_configuration][:domain_id] = current_domain.id
    params[:alert_configuration][:enabled_for_all_tags] = params[:alert_configuration][:enabled_for_all_tags] == 'true'
    unless params[:alert_configuration][:trigger_rules].is_a?(String)
      params[:alert_configuration][:trigger_rules] = (params[:alert_configuration][:trigger_rules] || {}).to_json
    end

    params[:tag_uids] ||= []
    pre_existing_tag_uids = @alert_configuration.tags.collect(&:uid)
    added_tag_uids = params[:tag_uids].difference(pre_existing_tag_uids)
    removed_tag_uids = pre_existing_tag_uids.difference(params[:tag_uids])

    if added_tag_uids.any?
      added_tags = current_domain.tags.where(uid: added_tag_uids)
      @alert_configuration.update!(alert_configuration_tags_attributes: added_tags.collect{ |tag| { tag_id: tag.id }})
    end

    if removed_tag_uids.any?
      @alert_configuration.alert_configuration_tags.joins(:tag).where(tag: { uid: removed_tag_uids }).destroy_all
    end

    params[:domain_user_uids] ||= []
    pre_existing_domain_user_uids = @alert_configuration.domain_users.collect(&:uid)
    added_domain_user_uids = params[:domain_user_uids].difference(pre_existing_domain_user_uids)
    removed_domain_user_uids = pre_existing_domain_user_uids.difference(params[:domain_user_uids])

    if added_domain_user_uids.any?
      added_domain_users = current_domain.domain_users.where(uid: added_domain_user_uids)
      @alert_configuration.update!(alert_configuration_domain_users_attributes: added_domain_users.collect{ |domain_user| { domain_user_id: domain_user.id }})
    end

    if removed_domain_user_uids.any?
      @alert_configuration.alert_configuration_domain_users.joins(:domain_user).where(domain_user: { uid: removed_domain_user_uids }).destroy_all
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
      :domain_id, 
      :type, 
      :name, 
      :trigger_rules, 
      :enabled_for_all_tags, 
      :disabled, 
      alert_configuration_domain_users_attributes: [:domain_user_id],
      alert_configuration_tags_attributes: [:tag_id]
    )
  end

  def next_path
    {
      'type' => trigger_rules_alert_configuration_path(@alert_configuration),
      'trigger_rules' => alert_configuration_tags_path(@alert_configuration),
      'tags' => alert_configuration_domain_users_path(@alert_configuration),
      'domain_users' => alert_configuration_path(@alert_configuration, review: true),
      'review' => alert_configuration_path(@alert_configuration)
    }[params[:current_view]]
  end
end