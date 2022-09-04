module TagManager
  class Promoter
    def self.promote_staged_changes(tags)
      return false if tags.count.zero?
      tags.each{ |tag| tag.draft_tag_configuration.promote! }
      TagsafeInstrumentationManager::InstrumentationWriter.new(tags.first.domain).write_current_instrumentation_to_cdn
    end
  end
end