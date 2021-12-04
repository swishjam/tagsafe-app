class LoggedOutController < ApplicationController
  layout 'logged_out_layout'
  before_action :ensure_logged_out

  def ensure_logged_out
    redirect_to tags_path unless current_user.nil?
  end
end