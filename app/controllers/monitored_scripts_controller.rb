class MonitoredScriptsController < ApplicationController
  before_action :authorize!
  
  def index
    @monitored_scripts = current_organization.monitored_scripts.includes(:script_changes).order('script_last_updated_at DESC')
  end

  def new
    @monitored_script = MonitoredScript.new
  end

  def show
    @monitored_script = MonitoredScript.includes(:script_changes).find(params[:id])
    ensure_organization_is_subscribed(@monitored_script)
  end

  def create
    script = MonitoredScript.find_by(url: params[:monitored_script][:url])
    if script.nil?
      script = MonitoredScript.create(monitored_script_params)
      unless script.valid?
        flash[:local_error] = script.errors.full_messages.join(' ')
        return redirect_to new_monitored_script_path
      end
    end

    current_organization.add_monitored_script(script)

    flash[:message] = "You are now monitoring #{script.url}"
    redirect_to monitored_script_path(script)
  end

  private
  def monitored_script_params
    params.require(:monitored_script).permit(:url)
  end
end