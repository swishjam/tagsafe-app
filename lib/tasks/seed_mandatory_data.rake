namespace :seed do
  task :mandatory_data => :environment do
    puts "Beginning seed."
    puts "Creating roles."
    %w[user user_admin tagsafe_admin].each do |role|
      unless Role.find_by(name: role)
        puts "Creating #{role} Role."
        Role.create(name: role)
      end
    end

    puts "Creating Execution Reasons."
    execution_reasons =  ['Tagsafe Provided', 'Manual', 'Scheduled', 'New Release', 'Activated Tag', 'Initial Audit']
    execution_reasons.each do |name|
      unless ExecutionReason.find_by(name: name)
        puts "Creating #{name} Execution Reason."
        ExecutionReason.create(name: name)
      end
    end

    puts "Creating TagCheckRegions"
    regions = [
      { aws_name: 'us-east-1', location: 'US East (North Virginia)' },
      { aws_name: 'us-east-2', location: 'US East (Ohio)' },
      { aws_name: 'us-west-1', location: 'US West (North California)' },
      { aws_name: 'us-west-2', location: 'US West (Oregon)' },
      { aws_name: 'af-south-1', location: 'Africa (Cape Town)' },
      { aws_name: 'ap-east-1', location: 'Asia Pacific (Hong Kong)' },
      { aws_name: 'ap-southeast-3', location: 'Asia Pacific (Jakarta)' },
      { aws_name: 'ap-south-1', location: 'Asia Pacific (Mumbai)' },
      { aws_name: 'ap-northeast-3', location: 'Asia Pacific (Osaka)' },
      { aws_name: 'ap-northeast-2', location: 'Asia Pacific (Seoul)' },
      { aws_name: 'ap-southeast-1', location: 'Asia Pacific (Singapore)' },
      { aws_name: 'ap-southeast-2', location: 'Asia Pacific (Sydney)' },
      { aws_name: 'ap-northeast-1', location: 'Asia Pacific (Tokyo)' },
      { aws_name: 'ca-central-1', location: 'Canada (Central)' },
      { aws_name: 'eu-central-1', location: 'Europe (Frankfurt)' },
      { aws_name: 'eu-west-1', location: 'Europe (Ireland)' },
      { aws_name: 'eu-west-2', location: 'Europe (London)' },
      { aws_name: 'eu-south-1', location: 'Europe (Milan)' },
      { aws_name: 'eu-north-1', location: 'Europe (Stockholm)' },
      { aws_name: 'me-south-1', location: 'Middle East (Bahrain)' },
      { aws_name: 'sa-east-1', location: 'South America (São Paulo)' },
    ]
    regions.each do |region|
      existing = TagCheckRegion.find_by(aws_name: region[:aws_name])
      if existing.present?
        puts "Updating #{region[:aws_name]} TagCheckRegion"
        existing.update!(region)
      else
        puts "Creating new #{region[:aws_name]} TagCheckRegion"
        TagCheckRegion.create!(region)
      end
    end

    puts "Syncing EventBridge rules from AWS..."
    # LambdaCronJobDataStore::AwsEventBridgeSynchronizer.update_tagsafes_event_bridge_rules_from_aws_regions!(TagCheckRegion.selectable)
  end
end