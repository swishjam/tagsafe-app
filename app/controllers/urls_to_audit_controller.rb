class UrlsToAuditController < LoggedInController
  def create
    tag = current_domain.tags.find(params[:tag_id])
    page_url = PageUrl.create_or_find_by_url(current_domain, params[:url_to_audit][:page_url])
    if !page_url.valid?
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_urls_to_audit_form",
        partial: 'urls_to_audit/form',
        locals: { domain: current_domain, tag: tag, errors: page_url.errors.full_messages }
      )
    else
      url_to_audit = tag.urls_to_audit.new(page_url: page_url)
      if url_to_audit.save
        current_user.broadcast_notification("Added #{page_url.full_url} to tag's audit URL list.", image: tag.try_image_url)
        render turbo_stream: turbo_stream.replace(
          "tag_#{tag.uid}_urls_to_audit",
          partial: 'urls_to_audit/index',
          locals: { domain: current_domain, urls_to_audit: tag.urls_to_audit, tag: tag }
        )
      else
        render turbo_stream: turbo_stream.replace(
          "tag_#{tag.uid}_urls_to_audit_form",
          partial: 'urls_to_audit/form',
          locals: { domain: current_domain, tag: tag, errors: url_to_audit.errors.full_messages }
        )
      end
    end
  rescue PageUrl::InvalidUrlError => e
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_urls_to_audit_form",
      partial: 'urls_to_audit/form',
      locals: { domain: current_domain, urls_to_audit: tag.urls_to_audit, tag: tag, errors: [e.message] }
    )
    # LEGACY TAGSAFE-HOSTED URL LOGIC, REVISIT IF WE WANT TO RE-IMPLEMENT
    # params[:url_to_audit][:audit_url] = params[:url_to_audit][:display_url]
    # if params[:url_to_audit][:production_url_version] == '1'
    #   params[:url_to_audit].delete(:production_url_version)
    #   params[:url_to_audit][:tagsafe_hosted] = false
    #   tag.urls_to_audit.create(url_to_audit_params)
    # end
    
    # if Flag.flag_is_true(current_organization, 'tagsafe_hosted_site_enabled') && params[:url_to_audit][:tagsafe_hosted_version] == '1'
    #   params[:url_to_audit].delete(:tagsafe_hosted_version)
    #   mock_site_moderator = TagSafeHostedSiteGenerator.new(params[:url_to_audit][:display_url])
    #   mock_site_moderator.generate_tagsafe_hosted_site
    #   params[:url_to_audit][:audit_url] = mock_site_moderator.s3_website_url
    #   params[:url_to_audit][:tagsafe_hosted] = true
    #   tag.urls_to_audit.create(url_to_audit_params)
    # end
  end

  def destroy
    tag = current_domain.tags.find(params[:tag_id])
    url_to_audit = tag.urls_to_audit.find(params[:id])
    if url_to_audit.destroy
      # current_user.broadcast_notification("Removed #{url_to_audit.page_url.full_url} from #{tag.try_friendly_name}'s audit list.")
      render turbo_stream: turbo_stream.replace(
        "tag_#{tag.uid}_urls_to_audit",
        partial: 'urls_to_audit/index',
        locals: { domain: current_domain, urls_to_audit: tag.urls_to_audit, tag: tag }
      )
    else
      current_user.broadcast_notification(url_to_audit.errors.full_messages, error: true)
    end
  end

  private

  # def url_to_audit_params
  #   params.require(:url_to_audit).permit(:tag_id, :display_url, :audit_url, :tagsafe_hosted, :primary)
  # end
end