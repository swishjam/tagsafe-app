class CurrentLiveTagVersionDecider
  def initialize(tag_version)
    @tag_version = tag_version
  end

  def make_live_if_criteria_is_met!
    # TODO: make a decision based off critiera
    @tag_version.tag.set_current_live_tag_version_and_publish_instrumentation(@tag_version)
  end
end