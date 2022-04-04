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
      { aws_region_name: 'us-east-1', location: 'US East (North Virginia)' },
      { aws_region_name: 'us-east-2', location: 'US East (Ohio)' },
      { aws_region_name: 'us-west-1', location: 'US West (North California)' },
      { aws_region_name: 'us-west-2', location: 'US West (Oregon)' },
      { aws_region_name: 'af-south-1', location: 'Africa (Cape Town)' },
      { aws_region_name: 'ap-east-1', location: 'Asia Pacific (Hong Kong)' },
      { aws_region_name: 'ap-southeast-3', location: 'Asia Pacific (Jakarta)' },
      { aws_region_name: 'ap-south-1', location: 'Asia Pacific (Mumbai)' },
      { aws_region_name: 'ap-northeast-3', location: 'Asia Pacific (Osaka)' },
      { aws_region_name: 'ap-northeast-2', location: 'Asia Pacific (Seoul)' },
      { aws_region_name: 'ap-southeast-1', location: 'Asia Pacific (Singapore)' },
      { aws_region_name: 'ap-southeast-2', location: 'Asia Pacific (Sydney)' },
      { aws_region_name: 'ap-northeast-1', location: 'Asia Pacific (Tokyo)' },
      { aws_region_name: 'ca-central-1', location: 'Canada (Central)' },
      { aws_region_name: 'eu-central-1', location: 'Europe (Frankfurt)' },
      { aws_region_name: 'eu-west-1', location: 'Europe (Ireland)' },
      { aws_region_name: 'eu-west-2', location: 'Europe (London)' },
      { aws_region_name: 'eu-south-1', location: 'Europe (Milan)' },
      { aws_region_name: 'eu-north-1', location: 'Europe (Stockholm)' },
      { aws_region_name: 'me-south-1', location: 'Middle East (Bahrain)' },
      { aws_region_name: 'sa-east-1', location: 'South America (São Paulo)' },
    ]
    regions.each do |region|
      existing = TagCheckRegion.find_by(aws_region_name: region[:aws_region_name])
      if existing.present?
        puts "Updating #{region[:aws_region_name]} TagCheckRegion"
        existing.update!(region)
      else
        puts "Creating new #{region[:aws_region_name]} TagCheckRegion"
        TagCheckRegion.create!(region)
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