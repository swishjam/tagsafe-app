class LoggedOutController < ApplicationController
  before_action :ensure_logged_out

  layout 'logged_out_layout'
end