namespace :sync do
  task :create_or_update_aws_event_bridge_rules => :environment do
    UptimeRegion.selectable.each do |uptime_region|
      aws_rules = TagsafeAws::EventBridge.list_rules(region: uptime_region.aws_region_name).rules
      aws_rules.each do |aws_rule|
        tagsafe_aws_event_bridge_rule = AwsEventBridgeRule.find_by(region: uptime_region.aws_region_name, name: aws_rule.name)
        if tagsafe_aws_event_bridge_rule.present?
          puts "Updating Tagsafe's AwsEventBridgeRule #{uptime_region.aws_region_name}'s #{aws_rule.name} rule..."
          tagsafe_aws_event_bridge_rule.update!(
            name: aws_rule.name,
            region: uptime_region.aws_region_name,
            enabled: aws_rule.state == 'ENABLED'
          )
        else
          puts "Creating new Tagsafe AwsEventBridgeRule for #{uptime_region.aws_region_name} region: #{aws_rule.name}..."
          klass = aws_rule.name.include?('uptime-check') ? UptimeCheckScheduleAwsEventBridgeRule : ReleaseCheckScheduleAwsEventBridgeRule
          klass.create!(
            name: aws_rule.name,
            enabled: aws_rule.state == 'ENABLED',
            region: uptime_region.aws_region_name
          )
        end
      end
    end

  end

  task :enable_or_disable_aws_event_bridge_rules_based_on_uptime_check_configurations => :environment do
    ReleaseCheckScheduleAwsEventBridgeRule.all.each do |uptime_check_schedule_aws_event_bridge_rule|
      if uptime_check_schedule_aws_event_bridge_rule.tags_being_checked_for_interval.none?
        puts "Disabling #{uptime_check_schedule_aws_event_bridge_rule.associated_release_check_minute_interval} minute AWS Event Bridge schedule rule for #{uptime_check_schedule_aws_event_bridge_rule.uptime_region.aws_region_name} region."
        uptime_check_schedule_aws_event_bridge_rule.disable!
      else
        puts "Enabling #{uptime_check_schedule_aws_event_bridge_rule.associated_release_check_minute_interval} minute AWS Event Bridge schedule rule for #{uptime_check_schedule_aws_event_bridge_rule.uptime_region.aws_region_name} region."
        uptime_check_schedule_aws_event_bridge_rule.enable!
      end
    end
  end
end