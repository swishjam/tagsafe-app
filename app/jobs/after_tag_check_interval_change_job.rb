class AfterTagCheckIntervalChangeJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(tag_id, previous_interval:, new_interval:)
    tag = Tag.find(tag_id)
    data_store_manager = LambdaCronJobDataStore::TagCheckIntervals.new(tag)
    data_store_manager.remove_interval_for_all_of_tags_tag_check_regions(previous_interval)
    data_store_manager.add_interval_for_all_of_tags_tag_check_regions(new_interval)
    LambdaCronJobDataStore::AwsEventBridgeSynchronizer.sync_regions_into_aws!(tag.tag_check_regions)
    tag.run_tag_check_now! if previous_interval.nil? && !new_interval.nil?
  end
end