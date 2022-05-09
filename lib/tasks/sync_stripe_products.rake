namespace :sync do
  task :stripe_products => :environment do |_, args|
    fetch_and_capture_stripe_products
  end

  task :create_stripe_products => :environment do
    saas_stripe_products = [
      {
        name: 'Starter',
        prices: [
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'starter',
            unit_amount_decimal: 0,
            nickname: 'Monthly rate',
            currency: 'usd',
            recurring: {
              interval: 'month'
            }
          },
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'starter',
            unit_amount_decimal: 0,
            nickname: 'Annual rate',
            currency: 'usd',
            recurring: {
              interval: 'year'
            }
          }
        ]
      },
      { 
        name: 'Scale',
        prices: [
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'scale',
            unit_amount_decimal: 59_99,
            nickname: 'Monthly rate',
            currency: 'usd',
            recurring: {
              interval: 'month'
            }
          },
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'scale',
            unit_amount_decimal: 575_90,
            nickname: 'Annual rate',
            currency: 'usd',
            recurring: {
              interval: 'year'
            }
          }
        ]
      },
      {
        name: 'Pro',
        prices: [
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'pro',
            unit_amount_decimal: 299_00,
            nickname: 'Monthly rate',
            currency: 'usd',
            recurring: {
              interval: 'month'
            }
          },
          {
            subscription_price_option_klass: SaasFeeSubscriptionPriceOption,
            subscription_package_type: 'pro',
            unit_amount_decimal: 2870_40,
            nickname: 'Annual rate',
            currency: 'usd',
            recurring: {
              interval: 'year'
            }
          }
        ]
      }
    ]
    usage_based_stripe_products = [
      {
        name: "Release Monitoring",
        prices: [
          {
            subscription_price_option_klass: PerReleaseCheckSubscriptionPriceOption,
            subscription_package_type: 'starter',
            nickname: 'Starter Plan',
            currency: 'usd',
            billing_scheme: 'per_unit',
            recurring: { 
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            unit_amount: 0
          },
          {
            subscription_price_option_klass: PerReleaseCheckSubscriptionPriceOption,
            subscription_package_type: 'scale',
            billing_scheme: 'tiered',
            nickname: 'Scale Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 10_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 0.25 }
            ]
          },
          {
            subscription_price_option_klass: PerReleaseCheckSubscriptionPriceOption,
            subscription_package_type: 'pro',
            billing_scheme: 'tiered',
            nickname: 'Pro Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 100_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 0.25 }
            ]
          }
        ]
      },
      {
        name: "Uptime Monitoring",
        prices: [
          {
            subscription_price_option_klass: PerUptimeCheckSubscriptionPriceOption,
            subscription_package_type: 'starter',
            nickname: 'Starter Plan',
            currency: 'usd',
            billing_scheme: 'per_unit',
            recurring: { 
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            unit_amount: 0
          },
          {
            subscription_price_option_klass: PerUptimeCheckSubscriptionPriceOption,
            subscription_package_type: 'scale',
            billing_scheme: 'tiered',
            nickname: 'Scale Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 50_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 0.25 }
            ]
          },
          {
            subscription_price_option_klass: PerUptimeCheckSubscriptionPriceOption,
            subscription_package_type: 'pro',
            billing_scheme: 'tiered',
            nickname: 'Pro Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 150_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 0.25 }
            ]
          }
        ]
      },
      {
        name: "Automated Performance Audits",
        prices: [
          {
            subscription_price_option_klass: PerAutomatedPerformanceAuditSubscriptionPriceOption,
            subscription_package_type: 'starter',
            nickname: 'Starter Plan',
            currency: 'usd',
            billing_scheme: 'per_unit',
            recurring: { 
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            unit_amount: 0
          },
          {
            subscription_price_option_klass: PerAutomatedPerformanceAuditSubscriptionPriceOption,
            subscription_package_type: 'scale',
            billing_scheme: 'tiered',
            nickname: 'Scale Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 2_500, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 5 }
            ]
          },
          {
            subscription_price_option_klass: PerAutomatedPerformanceAuditSubscriptionPriceOption,
            subscription_package_type: 'pro',
            billing_scheme: 'tiered',
            nickname: 'Pro Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 5_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 5 }
            ]
          }
        ]
      },
      {
        name: "Automated Test Runs",
        prices: [
          {
            subscription_price_option_klass: PerAutomatedTestRunSubscriptionPriceOption,
            subscription_package_type: 'starter',
            nickname: 'Starter Plan',
            currency: 'usd',
            billing_scheme: 'per_unit',
            recurring: { 
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            unit_amount: 0
          },
          {
            subscription_price_option_klass: PerAutomatedTestRunSubscriptionPriceOption,
            subscription_package_type: 'scale',
            billing_scheme: 'tiered',
            nickname: 'Scale Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 5_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 5 }
            ]
          },
          {
            subscription_price_option_klass: PerAutomatedTestRunSubscriptionPriceOption,
            subscription_package_type: 'pro',
            billing_scheme: 'tiered',
            nickname: 'Pro Plan',
            currency: 'usd',
            recurring: {
              interval: 'month',
              aggregate_usage: 'sum',
              usage_type: 'metered'
            },
            tiers_mode: 'graduated',
            tiers: [
              { up_to: 10_000, unit_amount_decimal: 0 },
              { up_to: 'inf', unit_amount_decimal: 5 }
            ]
          }
        ]
      }
    ]
    saas_stripe_products.concat(usage_based_stripe_products).each do |product_data|
      stripe_product_name = Rails.env.production? ? product_data[:name] : "#{product_data[:name]} - #{Rails.env}"
      puts "Creating Stripe Product: #{stripe_product_name}"
      stripe_product = Stripe::Product.create(name: stripe_product_name)

      product_data[:prices].each do |price_data|
        subscription_price_option_klass = price_data.delete(:subscription_price_option_klass)
        subscription_package_type = price_data.delete(:subscription_package_type)
        
        puts "Creating Stripe Price: #{stripe_product_name} - #{price_data[:nickname]}"
        stripe_price = Stripe::Price.create(price_data.merge(product: stripe_product.id))

        puts "Creating Tagsafe #{subscription_price_option_klass.to_s}: #{stripe_product_name} - #{price_data[:nickname]}"
        subscription_price_option_klass.create!(
          stripe_price_id: stripe_price.id, 
          name: "#{stripe_product_name} - #{price_data[:nickname]}", 
          subscription_package_type: subscription_package_type,
          billing_interval: price_data[:recurring][:interval],
          price_in_cents: price_data[:unit_amount_decimal] || 0
        )
      end
    end
  end
end



def fetch_and_capture_stripe_products(starting_after = nil)
  response = Stripe::Product.list(active: true, starting_after: starting_after)
  products = response.data
  products.each do |stripe_product|
    if stripe_product.metadata['Tagsafe Model'] && stripe_product.metadata['Tagsafe SubscriptionPriceOption Name']
      begin
        subscription_price_klass = stripe_product.metadata['Tagsafe Model'].constantize
        fetch_and_capture_stripe_prices(stripe_product: stripe_product, subscription_price_klass: subscription_price_klass)
      rescue => exception
        puts "Unrecognized SubscriptionPrice model: #{stripe_product.metadata['Tagsafe Model']} - #{exception.message}"
      end
    else
      puts "#{stripe_product.name} most have `Tagsafe Model` and `Tagsafe SubscriptionPrice Name` metadata keys, cannot create a SubscriptionPriceOption."
    end
  end
  fetch_and_capture_stripe_products(products.last.id) if response.has_more
end

def fetch_and_capture_stripe_prices(stripe_product:, subscription_price_klass:, starting_after: nil)
  response = Stripe::Price.list(product: stripe_product.id)
  stripe_prices = response.data
  puts "Creating #{stripe_prices.count} SubscriptionPriceOptions for product #{stripe_product.name}"
  stripe_prices.each do |stripe_price|
    puts "Creating #{subscription_price_klass.to_s} (#{stripe_product.name}) - #{stripe_price.unit_amount_decimal.to_f} cents)"
    subscription_price_klass.create!(
      name: stripe_product.metadata['Tagsafe SubscriptionPrice Name'], 
      stripe_price_id: stripe_price.id, 
      price_in_cents: stripe_price.unit_amount_decimal.to_f
    )
  end
  fetch_and_capture_stripe_prices(
    stripe_product: stripe_product, 
    subscription_price_klass: subscription_price_klass, 
    starting_after: prices.last.id
  ) if response.has_more
end