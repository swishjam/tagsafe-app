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
    execution_reasons =  ['Manual Execution', 'Scheduled Execution', 'New Tag Version', 'Activated Tag', 'Test', 'Initial Audit', 'Retry']
    execution_reasons.each do |name|
      unless ExecutionReason.find_by(name: name)
        puts "Creating #{name} Execution Reason."
        ExecutionReason.create(name: name)
      end
    end

    puts "Creating Subscription Options"
    subscription_options = [
      {
        name: 'Basic Plan', 
        slug: 'basic',
        stripe_flat_fee_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_MONTHLY_PRICE_ID'),
        stripe_flat_fee_annual_price_id: nil,
        stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
        stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
        stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_BASIC_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
      },
      {
        name: 'Starter Plan', 
        slug: 'starter',
        stripe_flat_fee_monthly_price_id: ENV.fetch("STRIPE_STARTER_PLAN_MONTHLY_PRICE_ID"),
        stripe_flat_fee_annual_price_id: nil,
        stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
        stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
        stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_STARTER_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
      },
      {
        name: 'Pro Plan', 
        slug: 'pro',
        stripe_flat_fee_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_MONTHLY_PRICE_ID'),
        stripe_flat_fee_annual_price_id: nil,
        stripe_tag_check_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_TAG_CHECK_MONTHLY_PRICE_ID'),
        stripe_performance_audit_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_PERFORMANCE_AUDIT_MONTHLY_PRICE_ID'),
        stripe_functional_test_monthly_price_id: ENV.fetch('STRIPE_PRO_PLAN_FUNCTIONAL_TEST_MONTHLY_PRICE_ID')
      }
    ]
    subscription_options.each do |subscription|
      unless sc = SubscriptionOption.find_by(slug: subscription[:slug])
        puts "Creating #{subscription[:name]} Subscription Category."
        SubscriptionOption.create(subscription)
      else
        sc.update!(subscription)
      end
    end
  end
end