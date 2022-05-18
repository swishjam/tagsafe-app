namespace :sync do
  task :create_or_update_aws_event_bridge_rules => :environment do
    DataSynchronizers::AwsEventBridgeRules.import_from_aws
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