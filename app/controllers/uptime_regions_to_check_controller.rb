class UptimeRegionsToCheckController < LoggedInController
  def create
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    uptime_region_to_check = tag.uptime_regions_to_check.create(uptime_region_id: params[:uptime_region_id])
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_config_fields",
      partial: "tags/config_fields",
      locals: {
        domain: current_domain,
        tag: tag,
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag),
        notification_message: "Added #{uptime_region_to_check.uptime_region.location} to #{tag.try_friendly_name}'s uptime regions."
      }
    )
  end

  def destroy
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    uptime_region_to_check = UptimeRegionToCheck.find_by(uid: params[:uid])
    uptime_region_to_check.destroy
    render turbo_stream: turbo_stream.replace(
      "new_tag_#{tag.uid}_uptime_regions_to_check",
      partial: 'uptime_regions_to_check/new',
      locals:{ 
        tag: tag, 
        selectable_uptime_regions: UptimeRegion.selectable.not_enabled_on_tag(tag) 
      }
    )
  end
end