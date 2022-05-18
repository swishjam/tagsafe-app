FactoryBot.define do
  factory :one_minute_release_check_aws_event_bridge_rule, class: AwsEventBridgeRule do |t|
    type { "ReleaseCheckScheduleAwsEventBridgeRule" }
    enabled { true }
    region { ReleaseCheckScheduleAwsEventBridgeRule::RELEASE_CHECK_AWS_REGION }
    name { "#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-1-minute-release-check-schedule" }
  end
end