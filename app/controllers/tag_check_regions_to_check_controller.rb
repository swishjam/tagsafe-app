class TagCheckRegionsToCheckController < LoggedInController
  def create
    tag = current_domain.tags.find(params[:tag_id])
    tag_check_region_to_check = tag.tag_check_regions_to_check.create(tag_check_region_id: params[:tag_check_region_id])
    current_user.broadcast_notification(message: "Added #{tag_check_region_to_check.tag_check_region.location} region for uptime monitoring.", image: tag.try_image_url)
    render turbo_stream: turbo_stream.replace(
      "new_tag_#{tag.uid}_tag_check_regions_to_check",
      partial: 'tag_check_regions_to_check/new',
      locals:{ 
        tag: tag, 
        selectable_tag_check_regions: TagCheckRegion.selectable.not_enabled_on_tag(tag) 
      }
    )
  end

  def destroy
    tag = current_domain.tags.find(params[:tag_id])
    tag_check_region_to_check = TagCheckRegionToCheck.find(params[:id])
    # silly validation on destroy isn't working...
    if tag_check_region_to_check.user_can_destroy?
      tag_check_region_to_check.destroy
      render turbo_stream: turbo_stream.replace(
        "new_tag_#{tag.uid}_tag_check_regions_to_check",
        partial: 'tag_check_regions_to_check/new',
        locals:{ 
          tag: tag, 
          selectable_tag_check_regions: TagCheckRegion.selectable.not_enabled_on_tag(tag) 
        }
      )
    else
      current_user.broadcast_notification(message: "Cannot remove the #{tag_check_region_to_check.tag_check_region.location} region, as it is the region used for release monitoring. Turn off Uptime Monitoring if you'd no longer to like to monitor the tag's uptime at all.")
    end
  end
end