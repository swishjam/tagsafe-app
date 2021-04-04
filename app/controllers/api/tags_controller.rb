module Api
  class TagsController < Api::BaseController
    before_action :find_and_permit_tag

    def toggle_is_third_party
      @tag.toggle_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@tag.try_friendly_name} will #{@tag.is_third_party_tag ? 'now' : 'no longer'} be considered a third party tag. This tag will #{@tag.is_third_party_tag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    def toggle_allowed_third_party_tag
      @tag.toggle_allowed_third_party_flag!
      render_msg(true, "Successfully updated tag. #{@tag.try_friendly_name} will #{@tag.allowed_third_party_flag ? 'now' : 'no longer'} be considered an 'allowed' third party tag. This tag will #{@tag.allowed_third_party_flag ? 'now' : 'no longer'} be blocked in audits moving forward.")
    end

    private

    def find_and_permit_tag
      @tag = Tag.find(params[:id])
      permitted_to_view?(@tag, raise_error: true)
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