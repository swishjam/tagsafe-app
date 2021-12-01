FactoryBot.define do
  factory :tag do
    full_url { 'https://www.thirdpartytag.com/script.js' }
    url_domain { 'www.thirdpartytag.com' }
    url_path { '/script.js' }
    # url_query_param { nil }
  end
end