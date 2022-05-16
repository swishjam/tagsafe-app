class FeaturePriceInCredits < ApplicationRecord
  self.table_name = :feature_prices_in_credits

  belongs_to :domain

  DEFAULTS_FOR_PACKAGE = {
    starter: {
      automated_performance_audit_price: 5,
      automated_test_run_price: 5,
      manual_performance_audit_price: 2.5,
      manual_test_run_price: 2.5,
      puppeteer_recording_price: 1,
      speed_index_filmstrip_price: 1,
      resource_waterfall_price: 2,
      uptime_check_price: 0.01,
      release_check_price: 0.1
    },
    scale: {
      automated_performance_audit_price: 5,
      automated_test_run_price: 5,
      manual_performance_audit_price: 0,
      manual_test_run_price: 0,
      puppeteer_recording_price: 1,
      speed_index_filmstrip_price: 1,
      resource_waterfall_price: 2,
      uptime_check_price: 0.01,
      release_check_price: 0.1
    },
    pro: {
      automated_performance_audit_price: 5,
      automated_test_run_price: 5,
      manual_performance_audit_price: 0,
      manual_test_run_price: 0,
      puppeteer_recording_price: 1,
      speed_index_filmstrip_price: 1,
      resource_waterfall_price: 2,
      uptime_check_price: 0.01,
      release_check_price: 0.1
    }
  }

  def self.create_or_update_for_domain_by_subscription_package(package_type, domain)
    price_attrs_for_package = DEFAULTS_FOR_PACKAGE[package_type.to_sym]
    if domain.feature_prices_in_credits.present?
      domain.feature_prices_in_credits.update!(price_attrs_for_package)
    else
      create!(price_attrs_for_package.merge(domain: domain))
    end
  end
end