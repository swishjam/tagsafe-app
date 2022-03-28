FactoryBot.define do
  factory :url_to_audit, class: UrlToAudit.to_s do
    association :tag
    association :page_url
  end
end