module TagManager
  class Promoter
    def self.promote_staged_changes(tags)
      return false if tags.count.zero?
      build_description = TagsafeInstrumentationManager::BuildDescriptionComposer.compose_build_description_for_tags_being_promoted(tags)
      tags.each{ |tag| tag.draft_tag_configuration.promote! }
      TagsafeInstrumentationManager::InstrumentationWriter.new(tags.first.domain).write_current_instrumentation_to_cdn
      InstrumentationBuild.create!(domain: tags.first.domain, description: build_description)
    end
  end
end