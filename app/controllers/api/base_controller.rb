module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :check_api_token

    def check_api_token
    end
  end
end