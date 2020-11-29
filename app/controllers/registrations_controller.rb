class RegistrationsController < ApplicationController
  def new
    @organization = Organization.new
  end

  def create
    Organization.create(organization_params)
  end

  private

  def organization_params
    params.require(:organization).permit(:name, users_attributes: [:email, :password_digest])
  end
end