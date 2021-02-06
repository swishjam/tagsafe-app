class OrganizationsController < LoggedInController
  layout 'logged_out_layout'
  skip_before_action :ensure_organization

  def new
    @organization = Organization.new
  end

  def create
    params[:organization][:domains_attributes]['0']['url'] = params[:domain][:protocol] + params[:organization][:domains_attributes]['0']['url']
    @organization = Organization.new(organization_params)
    if @organization.save
      @organization.add_user(current_user)
      display_toast_message("Welcome to TagSafe")
      redirect_to scripts_path
    else
      display_inline_errors(@organization.errors.full_messages)
      render :new
    end
  end

  private
  def organization_params
    params.require(:organization).permit(:name, domains_attributes: [:url])
  end
end