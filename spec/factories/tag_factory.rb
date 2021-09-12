FactoryBot.define do
  factory :tag do
    full_url { 'https://cdn.test.com/js' }
    url_domain { 'cdn.test.com' }
    url_path { '/js' }
    # url_query_param { nil }
  end
end