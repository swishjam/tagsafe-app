# class AfterTagsUptimeRegionsToCheckChangedJob < ApplicationJob
#   queue_as TagsafeQueue.CRITICAL

#   def perform(tag_id, uptime_region_id, removed: false, added: false)
#     tag = Tag.find(tag_id)
#     uptime_region = UptimeRegion.find(uptime_region_id)
#     data_store_manager = LambdaCronJobDataStore::ReleaseCheckIntervals.new(tag)
#     if removed
#       data_store_manager.remove_tags_current_interval_from_uptime_region(uptime_region)
#     elsif added
#       data_store_manager.add_tags_current_interval_to_uptime_region(uptime_region)
#     else
#       raise StandardError, "Must pass either `removed:` or `added:` to `.perform` to indicate the 
#                               uptime_region_to_check was added or removed for the tag."
#     end
#     LambdaCronJobDataStore::AwsEventBridgeSynchronizer.sync_regions_into_aws!(uptime_region)
#   end
# end