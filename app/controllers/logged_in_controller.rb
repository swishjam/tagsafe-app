class LoggedInController < ApplicationController
  before_action :authorize!

  layout 'logged_in_layout'
end