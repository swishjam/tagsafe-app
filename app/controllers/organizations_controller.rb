class OrganizationsController < LoggedInController
  layout 'logged_out_layout'
  skip_before_action :ensure_organization
  skip_before_action :ensure_domain

  def new
    redirect_to root_path if current_organization
    # redirect_to new_domain_path if current_organization
    @organization = Organization.new
  end

  def create
    params[:organization][:domains_attributes]['0']['url'] = params[:domain][:protocol] + params[:organization][:domains_attributes]['0']['url']
    params[:organization][:tag_version_retention_count] = (ENV['DEFAULT_TAG_VERSIONS_RETENTION_COUNT'] || '500').to_i
    params[:organization][:tag_check_retention_count] = (ENV['DEFAULT_TAG_CHECK_RETENTION_COUNT'] || '14400').to_i # 10 days worth when checking every minute
    @organization = Organization.new(organization_params)
    if @organization.save
      @organization.add_user(current_user)
      set_current_organization_for_user(current_user, @organization)
      redirect_to tags_path
    else
      display_inline_errors(@organization.errors.full_messages)
      render :new
    end
  end

  def update_current_organization
    org = current_user.organizations.find_by!(uid: params[:uid])
    set_current_organization_for_user(current_user, org)
    redirect_to tags_path
  end

  private
  def organization_params
    params.require(:organization).permit(:name, :tag_version_retention_count, :tag_check_retention_count, domains_attributes: [:url])
  end
end