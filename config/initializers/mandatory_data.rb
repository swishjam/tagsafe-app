return if Rails.env.test? || File.basename($PROGRAM_NAME) == 'rake' || ENV['BYPASS_EVENT_BRIDGE_RULE_VALIDATION']

MandatoryDataEnforcer::Roles.validate!
MandatoryDataEnforcer::UptimeRegions.validate!
MandatoryDataEnforcer::ExecutionReasons.validate!
MandatoryDataEnforcer::AwsEventBridgeRules.validate!