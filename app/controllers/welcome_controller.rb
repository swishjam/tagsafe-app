class WelcomeController < ApplicationController
  # before_action :ensure_logged_out
  before_action :authorize! # temporary
end