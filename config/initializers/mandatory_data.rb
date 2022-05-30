return if Rails.env.test? || File.basename($PROGRAM_NAME) == 'rake' || ENV['BYPASS_EVENT_BRIDGE_RULE_VALIDATION'].present?

MandatoryDataEnforcer::Roles.validate!
MandatoryDataEnforcer::UptimeRegions.validate!
MandatoryDataEnforcer::ExecutionReasons.validate!
MandatoryDataEnforcer::AwsEventBridgeRules.validate!(update_existing: ENV['UPDATE_EVENT_BRIDGE_RULES_ON_BOOT'].present?)