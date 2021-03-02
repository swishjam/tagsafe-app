module Api
  class ScriptSubscribersController < Api::BaseController
    before_action :find_and_permit_script_subscriber

    def toggle_is_third_party
      @script_subscriber.toggle_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@script_subscriber.try_friendly_name} will #{@script_subscriber.is_third_party_tag ? 'now' : 'no longer'} be considered a third party tag. This tag will #{@script_subscriber.is_third_party_tag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    def toggle_allowed_third_party_tag
      @script_subscriber.toggle_allowed_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@script_subscriber.try_friendly_name} will #{@script_subscriber.allowed_third_party_flag ? 'now' : 'no longer'} be considered an 'allowed' third party tag. This tag will #{@script_subscriber.allowed_third_party_flag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    private

    def find_and_permit_script_subscriber
      @script_subscriber = ScriptSubscriber.includes(:script).find(params[:id])
      permitted_to_view?(@script_subscriber, raise_error: true)
    rescue NoAccessError => e
      rrender_msg(false, 'No Access')
    end

    def render_msg(success, msg)
      render json: {
        success: success,
        message: msg
      }
    end
  end
end