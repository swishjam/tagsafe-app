namespace :sync do
  task :stripe_products => :environment do |_, args|
    fetch_and_capture_stripe_products
  end

  # task :create_default_stripe_products => :environment do |_, args|
  #   [
  #     { 
  #       klass: PerAutomatedPerformanceAuditSubscriptionPrice,
  #       price: 0.05,
  #     }, 
  #     { 
  #       klass: PerAutomatedTestRunSubscriptionPrice
  #     }, 
  #     { 
  #       klass: PerTagCheckSubscriptionPrice
  #     }
  #   ].each do |subscription_price_klass|
  #   end
  # end
end

def fetch_and_capture_stripe_products(starting_after = nil)
  response = Stripe::Product.list(active: true, starting_after: starting_after)
  products = response.data
  products.each do |stripe_product|
    if stripe_product.metadata['Tagsafe Model'] && stripe_product.metadata['Tagsafe SubscriptionPrice Name']
      begin
        subscription_price_klass = stripe_product.metadata['Tagsafe Model'].constantize
        fetch_and_capture_stripe_prices(stripe_product: stripe_product, subscription_price_klass: subscription_price_klass)
      rescue => exception
        puts "Unrecognized SubscriptionPrice model: #{stripe_product.metadata['Tagsafe Model']} - #{exception.message}"
      end
    else
      puts "#{stripe_product.name} most have `Tagsafe Model` and `Tagsafe SubscriptionPrice Name` metadata keys, cannot create a Tagsafe SubscriptionPrice."
    end
  end
  fetch_and_capture_stripe_products(products.last.id) if response.has_more
end

def fetch_and_capture_stripe_prices(stripe_product:, subscription_price_klass:, starting_after: nil)
  response = Stripe::Price.list(product: stripe_product.id)
  stripe_prices = response.data
  puts "Creating #{stripe_prices.count} SubscriptionPrices for product #{stripe_product.name}"
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