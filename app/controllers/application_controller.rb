class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  def __blank
    render plain: 'ok'
  end
end
