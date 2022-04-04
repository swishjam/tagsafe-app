namespace :sync do
  task :tag_check_lambda_configurations => :environment do |_, args|
    Tag.all.each do |tag|
      puts "Syncing #{tag.url_based_on_preferences}...."
      LambdaCronJobDataStore::TagCheckIntervals.new(tag).sync_current_tag_check_interval_for_tags_tag_check_regions
      LambdaCronJobDataStore::TagCheckConfigurations.new(tag).update_tag_check_configuration
      puts "updated #{tag.url_based_on_preferences}"
    end
  end
end