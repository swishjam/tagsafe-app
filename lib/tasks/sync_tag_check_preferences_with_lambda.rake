namespace :sync do
  task :tag_check_lambda_configurations => :environment do |_, args|
    overall_start_time = Time.now
    Tag.all.each do |tag|
      tag_start_time = Time.now
      puts "Syncing #{tag.url_based_on_preferences}...."
      puts "Setting current TagCheck configuration for tag..."
      LambdaCronJobDataStore::TagCheckConfigurations.new(tag).update_tag_check_configuration
      puts "Removing existing TagCheck minute interval config for tag..."
      LambdaCronJobDataStore::TagCheckIntervals.remove_tag_id_from_every_tag_check_region(tag.id)
      puts "Adding current TagCheck minute interval config for tag..."
      LambdaCronJobDataStore::TagCheckIntervals.new(tag).add_interval_for_all_of_tags_tag_check_regions(tag.tag_preferences.tag_check_minute_interval)
      puts "Updated #{tag.url_based_on_preferences} in #{Time.now - tag_start_time} seconds.\n"
    end
    puts "Updating AWS EventBridge Rules based on current active/inactive configurations..."
    LambdaCronJobDataStore::AwsEventBridgeSynchronizer.sync_regions_into_aws!(TagCheckRegion.selectable)
    puts "Complete TagCheck Lambda synchronization in #{Time.now - overall_start_time} seconds!"
  end
end