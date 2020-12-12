module Api
  class ScriptSubscribersController < Api::BaseController
    before_action :find_and_permit

    def toggle_active
      if @script_subscriber.still_on_site?
        @script_subscriber.toggle_active_flag!
        if @script_subscriber.errors.any?
          render_msg(false, @script_subscriber.errors.full_messages.join('\n'))
        else
          render_msg(true, "You have successfully turned monitoring #{@script_subscriber.active ? 'on' : 'off'} for #{@script_subscriber.script.url}. Tag Safe will #{@script_subscriber.active? ? 'now' : 'no longer'} monitor changes, tests, and audits for this tag.")
        end
      else
        render_msg(false, "Cannot activate tag monitoring on a tag that is no longer on the site.")
      end
    end

    def toggle_is_third_party
      @script_subscriber.toggle_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@script_subscriber.try_friendly_name} will #{@script_subscriber.is_third_party_tag ? 'now' : 'no longer'} be considered a third party tag. This tag will #{@script_subscriber.is_third_party_tag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    def toggle_allowed_third_party_tag
      @script_subscriber.toggle_allowed_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@script_subscriber.try_friendly_name} will #{@script_subscriber.allowed_third_party_flag ? 'now' : 'no longer'} be considered an 'allowed' third party tag. This tag will #{@script_subscriber.allowed_third_party_flag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    private

    def find_and_permit
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