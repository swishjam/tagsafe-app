FactoryBot.define do
  factory :lighthouse_audit_type_current_tag, class: 'LighthouseAuditType' do
    name { 'Current Tag' }
  end

  factory :lighthouse_audit_type_without_tag, class: 'LighthouseAuditType' do
    name { 'Without Tag' }
  end

  factory :lighthouse_audit_type_average_current_tag, class: 'LighthouseAuditType' do
    name { 'Average Current Tag' }
  end

  factory :lighthouse_audit_type_average_without_tag, class: 'LighthouseAuditType' do
    name { 'Average Without Tag' }
  end

  factory :lighthouse_audit_type_delta, class: 'LighthouseAuditType' do
    name { 'Delta' }
  end
end