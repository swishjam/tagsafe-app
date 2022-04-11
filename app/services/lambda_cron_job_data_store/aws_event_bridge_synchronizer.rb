module LambdaCronJobDataStore
  class AwsEventBridgeSynchronizer
    class << self

      def sync_regions_into_aws!(tag_check_region_or_collection)
        tag_check_region_collection = tag_check_region_or_collection.is_a?(Enumerable) ? tag_check_region_or_collection : [tag_check_region_or_collection]
        tag_check_region_collection.each do |tag_check_region|
          config_for_region = LambdaCronJobDataStore::TagCheckIntervals.get_configuration_for_region(tag_check_region.aws_region_name)
          config_for_region.keys.each do |interval|
            aws_event_bridge_rule = tag_check_region.tag_check_schedule_aws_event_bridge_rules.for_interval(interval)
            if aws_event_bridge_rule.nil?
              Rails.logger.warn <<~MSG
                LambdaCronJobDataStore for #{tag_check_region.aws_region_name} has a tag check interval without an 
                associated TagCheckScheduleAwsEventBridgeRule! Either create the rule in Tagsafe because it is not synced, or remove 
                the key from the LambdaCronJobDataStore because it is invalid.
              MSG
            else
              regions_interval_config = config_for_region[interval]
              if regions_interval_config.empty? && aws_event_bridge_rule.enabled?
                aws_event_bridge_rule.disable!
              elsif !regions_interval_config.empty? && aws_event_bridge_rule.disabled?
                aws_event_bridge_rule.enable!
              end
            end
          end
        end
      end

      def update_tagsafes_event_bridge_rules_from_aws_regions!(tag_check_region_or_collection)
        tag_check_region_collection = tag_check_region_or_collection.is_a?(Enumerable) ? tag_check_region_or_collection : [tag_check_region_or_collection]
        tag_check_region_collection.each do |tag_check_region|
          aws_rules = TagsafeAws::EventBridge.list_rules(region: tag_check_region.aws_region_name).rules
          aws_rules.each do |aws_rule|
            interval = aws_rule.schedule_expression.tr('^0-9', '')
            tagsafe_aws_event_bridge_rule = tag_check_region.tag_check_schedule_aws_event_bridge_rules.for_interval(interval)
            if tagsafe_aws_event_bridge_rule.present?
              puts "Updating Tagsafe's TagCheckScheduleAwsEventBridgeRule #{tag_check_region.aws_region_name}'s #{interval} minute interval..."
              tagsafe_aws_event_bridge_rule.update!(
                name: aws_rule.name,
                associated_tag_check_minute_interval: interval,
                enabled: aws_rule.state == 'ENABLED'
              )
            else
              puts "Creating new TagCheckScheduleAwsEventBridgeRule for #{tag_check_region.aws_region_name}'s #{interval} minute interval..."
              tag_check_region.tag_check_schedule_aws_event_bridge_rules.create!(
                name: aws_rule.name,
                associated_tag_check_minute_interval: interval,
                enabled: aws_rule.state == 'ENABLED'
              )
            end
          end
        end
      end

    end
  end
end