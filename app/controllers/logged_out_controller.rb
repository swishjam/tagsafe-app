class LoggedOutController < ApplicationController
  before_action :ensure_logged_out

  layout 'logged_out_layout'

  def ensure_logged_out
    redirect_to scripts_path unless current_user.nil?
  end
end