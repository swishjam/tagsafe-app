namespace :sync do
  task :tag_check_schedule_aws_event_bridge_rules => :environment do
    LambdaCronJobDataStore::AwsEventBridgeSynchronizer.update_tagsafes_event_bridge_rules_from_aws_regions!(TagCheckRegion.selectable)
  end
end