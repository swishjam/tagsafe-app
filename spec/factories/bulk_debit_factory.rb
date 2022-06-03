FactoryBot.define do
  factory :bulk_debit do
    association :credit_wallet
    debit_amount { 10 }
    num_records_for_debited_date_range { 50 }
    start_date { Time.current.last_month.beginning_of_month }
    end_date { Time.current.last_month.end_of_month }
  end

  factory :uptime_checks_bulk_debit, parent: :bulk_debit do
    type { 'UptimeChecksBulkDebit' }
  end

  factory :release_checks_bulk_debit, parent: :bulk_debit do
    type { 'ReleaseChecksBulkDebit' }
  end
end