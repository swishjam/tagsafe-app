FactoryBot.define do
  factory :url_to_audit, class: 'UrlToAudit' do
    association :tag
  end
end