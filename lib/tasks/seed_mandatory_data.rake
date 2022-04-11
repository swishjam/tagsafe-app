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

    puts "Creating EventBridge rules..."
    EVENT_BRIDGE_RULE_DICTIONARY = {
      'development' => {
        'us-east-1' => {
          '1' => 'release-monitoring-develo-CheckDashtagsDashforDash-18I1ACKC16L21',
          '15' => 'release-monitoring-develo-CheckDashtagsDashforDash-TNY4CWFJFIA2',
          '30' => 'release-monitoring-develo-CheckDashtagsDashforDash-1HJTSDYLI43J4',
          '60' => 'release-monitoring-develo-CheckDashtagsDashforDash-106BA5UR8F38F',
          '180' => 'release-monitoring-develo-CheckDashtagsDashforDash-1EHYAJNR877D8',
          '360' => 'release-monitoring-develo-CheckDashtagsDashforDash-11WND1XSY4ZQD',
          '720' => 'release-monitoring-develo-CheckDashtagsDashforDash-D25F5CEVH1SA',
          '1440' => 'release-monitoring-develo-CheckDashtagsDashforDash-AHQ8TRAMA4L3'
        },
        'ca-central-1' => {
          '1' => 'release-monitoring-develo-CheckDashtagsDashforDash-18I1ACKC16L21',
          '15' => 'release-monitoring-develo-CheckDashtagsDashforDash-TNY4CWFJFIA2',
          '30' => 'release-monitoring-develo-CheckDashtagsDashforDash-1HJTSDYLI43J4',
          '60' => 'release-monitoring-develo-CheckDashtagsDashforDash-106BA5UR8F38F',
          '180' => 'release-monitoring-develo-CheckDashtagsDashforDash-1EHYAJNR877D8',
          '360' => 'release-monitoring-develo-CheckDashtagsDashforDash-11WND1XSY4ZQD',
          '720' => 'release-monitoring-develo-CheckDashtagsDashforDash-D25F5CEVH1SA',
          '1440' => 'release-monitoring-develo-CheckDashtagsDashforDash-AHQ8TRAMA4L3'
        }
      }
    }
    EVENT_BRIDGE_RULE_DICTIONARY[Rails.env].keys.each do |aws_region|
      event_bridge_interval_rules = EVENT_BRIDGE_RULE_DICTIONARY[Rails.env][aws_region]
      event_bridge_interval_rules.each do |interval, rule_name|
        existing_rule = TagCheckScheduleAwsEventBridgeRule.find_by(name: rule_name)
        event_bridge_rule = TagsafeAws::EventBridge.get_rule(rule_name, region: aws_region)
        event_bridge_rule_is_enabled = event_bridge_rule.state == 'ENABLED'
        if existing_rule
          puts "Updating #{rule_name} (#{aws_region} for #{interval} minute interval)"
          existing_rule.update!(
            region: aws_region,
            associated_tag_check_minute_interval: interval,
            enabled: event_bridge_rule_is_enabled
          )
        else
          puts "Creating #{rule_name} (#{aws_region} for #{interval} minute interval)"
          TagCheckScheduleAwsEventBridgeRule.create!(
            name: rule_name,
            region: aws_region,
            associated_tag_check_minute_interval: interval,
            enabled: event_bridge_rule_is_enabled
          )
        end 
      end
    end

    # puts "Creating Subscription Options"
    # subscription_options = [
    #   {
    #     name: 'Basic Plan', 
    #     slug: 'basic',
    #     stripe_flat_fee_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_MONTHLY_PRICE_ID'),
    #     stripe_flat_fee_annual_price_id: nil,
    #     stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
    #     stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
    #     stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
    #   },
    #   {
    #     name: 'Starter Plan', 
    #     slug: 'starter',
    #     stripe_flat_fee_monthly_price_id: ENV.fetch("STRIPE_STARTER_PLAN_MONTHLY_PRICE_ID"),
    #     stripe_flat_fee_annual_price_id: nil,
    #     stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
    #     stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
    #     stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
    #   },
    #   {
    #     name: 'Pro Plan', 
    #     slug: 'pro',
    #     stripe_flat_fee_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_MONTHLY_PRICE_ID'),
    #     stripe_flat_fee_annual_price_id: nil,
    #     stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
    #     stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
    #     stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
    #   }
    # ]
    # subscription_options.each do |subscription|
    #   unless sc = SubscriptionOption.find_by(slug: subscription[:slug])
    #     puts "Creating #{subscription[:name]} Subscription Category."
    #     SubscriptionOption.create(subscription)
    #   else
    #     sc.update!(subscription)
    #   end
    # end
  end
end