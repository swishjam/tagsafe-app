module Api
  class ScriptSubscribersController < Api::BaseController
    def toggle_active
      script_subscriber = ScriptSubscriber.includes(:script).find(params[:id])
      permitted_to_view?(script_subscriber.script)
      script_subscriber.toggle_active_flag!
      render json: {
        success: true,
        message: "You have successfully turned monitoring #{script_subscriber.active ? 'on' : 'off'} for #{script_subscriber.script.url}. Tag Safe will no longer monitor changes, tests, and audits for this tag."
      }
    end
    
    def toggle_lighthouse
      script_subscriber = ScriptSubscriber.includes(:script).find(params[:id])
      permitted_to_view?(script_subscriber)
      script_subscriber.toggle_lighthouse_flag!
      render json: {
        success: true,
        message: "You have successfully turned #{script_subscriber.lighthouse_preferences.should_run_audit ? 'on' : 'off'} lighthouse audits for #{script_subscriber.script.url}. Tag Safe will no longer run automated lighthouse audits for this tag."
      }
    end
  end
end