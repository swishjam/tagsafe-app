# class AfterTagsTagCheckRegionsToCheckChangedJob < ApplicationJob
#   queue_as TagsafeQueue.CRITICAL

#   def perform(tag_id, tag_check_region_id, removed: false, added: false)
#     tag = Tag.find(tag_id)
#     tag_check_region = TagCheckRegion.find(tag_check_region_id)
#     data_store_manager = LambdaCronJobDataStore::TagCheckIntervals.new(tag)
#     if removed
#       data_store_manager.remove_tags_current_interval_from_tag_check_region(tag_check_region)
#     elsif added
#       data_store_manager.add_tags_current_interval_to_tag_check_region(tag_check_region)
#     else
#       raise StandardError, "Must pass either `removed:` or `added:` to `.perform` to indicate the 
#                               tag_check_region_to_check was added or removed for the tag."
#     end
#     LambdaCronJobDataStore::AwsEventBridgeSynchronizer.sync_regions_into_aws!(tag_check_region)
#   end
# end