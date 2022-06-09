class AlertConfigurationsController < LoggedInController
  def index
    @alert_configurations = current_domain.alert_configurations.page(params[:page] || 1).per(10)
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
  end

  def create
    alert_configuration_klass = params[:alert_configuration][:type].constantize
    tags = current_domain.tags.where(uid: params[:tag_uids] || [])
    @alert_configuration = alert_configuration_klass.new(
      domain: current_domain,
      name: params[:alert_configuration][:name],
      enable_for_all_tags: params[:alert_configuration][:enable_for_all_tags] == 'true',
      alert_configuration_tags_attributes: tags.collect{ |tag| { tag_id: tag.id }},
      alert_configuration_domain_users_attributes: [{ domain_user_id: current_domain_user.id }],
      trigger_rules: params[:trigger_rules]
    )
    if @alert_configuration.save
      redirect_to alert_configuration_path(@alert_configuration)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    alert_configuration = current_domain_user.alert_configurations.find_by(uid: params[:uid])
    attr_being_updated = params[:alert_configuration].keys[0]
    priv_params_for_attr_being_updated = params.require(:alert_configuration).permit(attr_being_updated.to_sym)
    if alert_configuration.update(priv_params_for_attr_being_updated)
      current_user.broadcast_notification(message: "Alert settings updated.")
    else
      current_user.broadcast_notification(message: alert_configuration.errors.full_sentences.join('\n'))
    end
    head :ok
  end
end