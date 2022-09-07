module TagsafeInstrumentationManager
  class BuildDescriptionComposer
    def self.compose_build_description_for_tags_being_promoted(tags)
      description = ""
      tags.each do |tag|
        description << compose_build_description_for_tag(tag)
        description << "\n"
      end
      description
    end

    private

    def self.compose_build_description_for_tag(tag)
      configuration_being_promoted_to = tag.draft_tag_configuration
      previously_live_configuration = tag.live_tag_configuration
      if previously_live_configuration.nil?
        "Added #{tag.try_friendly_name}."
      else
        configuration_being_promoted_to = tag.draft_tag_configuration
        previously_live_configuration = tag.live_tag_configuration
        description = ""
        if configuration_being_promoted_to.release_check_minute_interval != previously_live_configuration.release_check_minute_interval
          description << "Updated #{tag.try_friendly_name} release check interval from #{previously_live_configuration.release_monitoring_interval_in_words} to #{configuration_being_promoted_to.release_monitoring_interval_in_words}.\n"
        end

        if configuration_being_promoted_to.load_type != previously_live_configuration.load_type
          description << "Updated #{tag.try_friendly_name} script load type from #{previously_live_configuration.load_type} to #{configuration_being_promoted_to.load_type}.\n"
        end

        if configuration_being_promoted_to.is_tagsafe_hosted != previously_live_configuration.is_tagsafe_hosted
          description << "Updated #{tag.try_friendly_name} to#{configuration_being_promoted_to.is_tagsafe_hosted ? ' ' : " no longer "}be Tagsafe-hosted.\n"
        end

        if configuration_being_promoted_to.script_inject_location != previously_live_configuration.script_inject_location
          description << "Updated #{tag.try_friendly_name} script location from #{previously_live_configuration.script_inject_location} to #{configuration_being_promoted_to.script_inject_location}.\n"
        end

        if configuration_being_promoted_to.script_inject_event != previously_live_configuration.script_inject_event
          description << "Updated #{tag.try_friendly_name} script inject event from #{previously_live_configuration.script_inject_event} to #{configuration_being_promoted_to.script_inject_event}.\n"
        end

        if configuration_being_promoted_to.enabled != previously_live_configuration.enabled
          description << "#{configuration_being_promoted_to.enabled ? "Enabled" : "Disabled"} #{tag.try_friendly_name}.\n"
        end

        description
      end
    end
  end
end