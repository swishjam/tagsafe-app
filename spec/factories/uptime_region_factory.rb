FactoryBot.define do
  factory :us_east_1, class: UptimeRegion do
    location { 'US East (N Virginia)' }
    aws_name { 'us-east-1' }
  end
end