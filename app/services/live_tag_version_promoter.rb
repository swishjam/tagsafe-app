class LiveTagVersionPromoter
  def initialize(tag_version)
    @tag_version = tag_version
  end

  def set_as_tags_live_version_if_criteria_is_met!
    if @tag_version.primary_audit.tagsafe_score >= 80
      @tag_version.tag.set_current_live_tag_version_and_publish_instrumentation(@tag_version)
    else
      @tag_version.update!(blocked_from_promoting_to_live: true)
      @tag_version.tag.container.users.each do |user|
        user.broadcast_notification(
          title: "🚨 #{@tag_version.tag.try_friendly_name} release blocked", 
          message: "Tagsafe blocked the release due to a low Tagsafe Score of #{@tag_version.primary_audit.formatted_tagsafe_score}.", 
          image: @tag_version.tag.try_image_url
        )
      end
    end
  end
end