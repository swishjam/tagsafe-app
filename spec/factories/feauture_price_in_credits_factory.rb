FactoryBot.define do
  factory :feature_price_in_credits do
    association :domain
    automated_performance_audit_price { 5.0 }
    automated_test_run_price { 5.0 }
    manual_performance_audit_price { 0.0 }
    manual_test_run_price { 0.0 }
    puppeteer_recording_price { 1.0 }
    speed_index_filmstrip_price { 1.0 }
    resource_waterfall_price { 2.0 }
    uptime_check_price { 0.01 }
    release_check_price { 0.1 }
  end
end