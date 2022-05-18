return if Rails.env.test?  

def validate_all_event_bridge_rules_exist_in_tagsafe(should_attempt_sync_if_missing_rules = true)
  unfound_release_check_intervals = []
  unfound_uptime_check_region_names = []

  TagPreference.SUPPORTED_RELEASE_CHECK_INTERVALS.each do |interval|
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(interval)
  rescue ActiveRecord::RecordNotFound => e
    puts "Unable to find `ReleaseCheckScheduleAwsEventBridgeRule` for #{interval} interval"
    unfound_release_check_intervals << interval
  end

  puts "Confirmed `ReleaseCheckScheduleAwsEventBridgeRule`s exist for #{TagPreference.SUPPORTED_RELEASE_CHECK_INTERVALS.join(', ')} minute intervals."

  UptimeRegion.selectable.each do |uptime_region|
    UptimeCheckScheduleAwsEventBridgeRule.for_uptime_region!(uptime_region)
  rescue ActiveRecord::RecordNotFound => e
    puts "Unable to find `UptimeCheckScheduleAwsEventBridgeRule` for #{uptime_region.aws_region_name} region"
    unfound_uptime_check_region_names << uptime_region.aws_region_name
  end

  if unfound_uptime_check_region_names.count > 0 || unfound_release_check_intervals.count > 0
    if should_attempt_sync_if_missing_rules
      puts "Missing #{unfound_uptime_check_region_names.count} `UptimeCheckScheduleAwsEventBridgeRules` for #{unfound_uptime_check_region_names.join(', ')} regions" if unfound_uptime_check_region_names.any?
      puts "Missing #{unfound_release_check_intervals.count} `ReleaseCheckScheduleAwsEventBridgeRules` for #{unfound_release_check_intervals.join(', ')} intervals" if unfound_release_check_intervals.any?
      DataSynchronizers::AwsEventBridgeRules.import_from_aws
      validate_all_event_bridge_rules_exist_in_tagsafe(false)
    else
      raise <<~ERR
        Unable to find #{unfound_uptime_check_region_names.count} UptimeCheck AWS Event Bridge Rules and #{unfound_release_check_intervals.count} ReleaseCheck AWS Event Bridge Rules event after attempting importing from AWS. \n
        Geppetto Lambda jobs likely needs to be pushed to AWS. \n
        Missing UptimeCheck regions: #{unfound_uptime_check_region_names.join(' ')} \n
        Missing ReleaseCheck intervals: #{unfound_release_check_intervals.join(' ')}
      ERR
    end
  else
    puts "Confirmed an `UptimeCheckScheduleAwsEventBridgeRule`s exists for #{UptimeRegion::SELECTABLE_AWS_REGION_NAMES.join(', ')} regions."
  end
end

if ENV['BYPASS_EVENT_BRIDGE_RULE_VALIDATION']
  puts "Skipping Event Bridge Rule validation."
else
  validate_all_event_bridge_rules_exist_in_tagsafe
end
