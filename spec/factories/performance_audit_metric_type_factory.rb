FactoryBot.define do
  factory :performance_audit_metric_type do
    title { 'DOM Complete' }
    key { 'DOMComplete' }
    unit { 'milliseconds' }
  end
end