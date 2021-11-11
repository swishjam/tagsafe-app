class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper

  def self.hide_navigation_on(*views)
    before_action only: views do 
      @hide_navigation = true
    end
  end
end
