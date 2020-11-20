class AdminController < ApplicationController
  before_action :verify_admin

  def verify_admin
  end
end