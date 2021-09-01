class ApplicationController < ActionController::Base
  class NoAccessError < StandardError; end
  protect_from_forgery with: :exception
  include ApplicationHelper

  def self.hide_navigation_on(*views)
    before_action only: views do 
      @hide_navigation = true
    end
  end
end
