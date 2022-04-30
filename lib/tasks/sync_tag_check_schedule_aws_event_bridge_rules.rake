namespace :sync do
  task :create_or_update_tag_check_schedule_aws_event_bridge_rules => :environment do

    TagCheckRegion.selectable.each do |tag_check_region|
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

  task :enable_or_disable_aws_event_bridge_rules_based_on_tag_check_configurations => :environment do
    TagCheckScheduleAwsEventBridgeRule.all.each do |tag_check_schedule_aws_event_bridge_rule|
      if tag_check_schedule_aws_event_bridge_rule.tags_being_checked_for_interval.none?
        puts "Disabling #{tag_check_schedule_aws_event_bridge_rule.associated_tag_check_minute_interval} minute AWS Event Bridge schedule rule for #{tag_check_schedule_aws_event_bridge_rule.tag_check_region.aws_region_name} region."
        tag_check_schedule_aws_event_bridge_rule.disable!
      else
        puts "Enabling #{tag_check_schedule_aws_event_bridge_rule.associated_tag_check_minute_interval} minute AWS Event Bridge schedule rule for #{tag_check_schedule_aws_event_bridge_rule.tag_check_region.aws_region_name} region."
        tag_check_schedule_aws_event_bridge_rule.enable!
      end
    end
  end
end