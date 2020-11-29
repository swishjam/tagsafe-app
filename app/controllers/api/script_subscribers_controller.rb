module Api
  class ScriptSubscribersController < Api::BaseController
    def toggle_active
      script_subscriber = ScriptSubscriber.includes(:script).find(params[:id])
      permitted_to_view?(script_subscriber.script)
      if script_subscriber.still_on_site?
        script_subscriber.toggle_active_flag!
        if script_subscriber.errors.any?
          render json: {
            success: false,
            message: script_subscriber.errors.full_messages.join('\n')
          }
        else
          render json: {
            success: true,
            message: "You have successfully turned monitoring #{script_subscriber.active ? 'on' : 'off'} for #{script_subscriber.script.url}. Tag Safe will no longer monitor changes, tests, and audits for this tag."
          }
        end
      else
        render json: {
          success: false,
          message: "Cannot activate tag monitoring on a tag that is no longer on the site."
        }
      end
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