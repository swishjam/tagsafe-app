class UrlsToAuditController < LoggedInController
  def create
    tag = current_domain.tags.find(params[:tag_id])
    
    params[:url_to_audit][:audit_url] = params[:url_to_audit][:display_url]
    if params[:url_to_audit][:production_url_version] == '1'
      params[:url_to_audit].delete(:production_url_version)
      params[:url_to_audit][:tagsafe_hosted] = false
      tag.urls_to_audit.create(url_to_audit_params)
    end
    
    if params[:url_to_audit][:tagsafe_hosted_version] == '1'
      params[:url_to_audit].delete(:tagsafe_hosted_version)
      mock_site_moderator = MockWebsiteModerator.new(params[:url_to_audit][:display_url])
      mock_site_moderator.create_mock_website_for_url
      params[:url_to_audit][:audit_url] = mock_site_moderator.s3_website_url
      params[:url_to_audit][:tagsafe_hosted] = true
      tag.urls_to_audit.create(url_to_audit_params)
    end

    current_user.broadcast_notification("Added new audit URL")
    
    render turbo_stream: turbo_stream.replace(
      'urls_to_audit',
      partial: 'form',
      locals: { urls_to_audit: tag.urls_to_audit, tag: tag, url_to_audit: UrlToAudit.new }
    )
  end

  def destroy
    tag = current_domain.tags.find(params[:tag_id])
    url_to_audit = tag.urls_to_audit.find(params[:id])
    if url_to_audit.destroy
      render turbo_stream: turbo_stream.replace(
        'urls_to_audit',
        partial: 'form',
        locals: { urls_to_audit: tag.reload.urls_to_audit, tag: tag, url_to_audit: UrlToAudit.new }
      )
    else
      current_user.broadcast_notification(url_to_audit.errors.full_messages, error: true)
    end
  end

  private

  def url_to_audit_params
    params.require(:url_to_audit).permit(:tag_id, :display_url, :audit_url, :tagsafe_hosted, :primary)
  end
end